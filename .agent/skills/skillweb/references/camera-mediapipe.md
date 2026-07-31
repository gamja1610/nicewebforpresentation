# 실시간 카메라 — getUserMedia + MediaPipe

**언제 쓰나**: 프로젝트가 얼굴/손/포즈 인식을 실제로 다룰 때만 MediaPipe까지 붙인다. 단순히 "카메라로 뭔가 비추는 느낌"만 필요하면 아래 1번(순수 getUserMedia + Canvas 필터)만으로 충분하다.

## 1. 기본 웹캠 피드 (모든 카메라 슬라이드의 베이스, 검증된 표준 API)

```html
<video id="cam" autoplay playsinline muted style="display:none"></video>
<canvas id="cam-canvas"></canvas>
<div id="cam-fallback" style="display:none">카메라를 사용할 수 없습니다 — 데모 이미지로 대체됩니다.</div>
<script>
async function startCamera() {
  const video = document.getElementById("cam");
  const canvas = document.getElementById("cam-canvas");
  const ctx = canvas.getContext("2d");
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } });
    video.srcObject = stream;
    await video.play();
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    return { video, ctx, canvas };
  } catch (err) {
    document.getElementById("cam-fallback").style.display = "block";
    return null; // 반드시 이 null을 체크해서 fallback UI로 전환한다
  }
}
</script>
```

간단한 "쩌는" 느낌은 라이브러리 없이 Canvas 픽셀 처리만으로도 충분하다 — 예: 잔상 트레일 효과.

```js
function drawTrailFrame(cam) {
  cam.ctx.globalAlpha = 0.15;
  cam.ctx.fillStyle = "black";
  cam.ctx.fillRect(0, 0, cam.canvas.width, cam.canvas.height);
  cam.ctx.globalAlpha = 1;
  cam.ctx.drawImage(cam.video, 0, 0, cam.canvas.width, cam.canvas.height);
  requestAnimationFrame(() => drawTrailFrame(cam));
}
```

## 2. 얼굴 랜드마크 (FaceLandmarker) — 공식 문서 검증된 코드

출처: [MediaPipe FaceLandmarker Web docs](https://developers.google.com/edge/mediapipe/solutions/vision/face_landmarker/web_js)

```html
<script type="module">
import { FilesetResolver, FaceLandmarker } from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

async function setupFaceLandmarker() {
  const vision = await FilesetResolver.forVisionTasks(
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm"
  );
  return await FaceLandmarker.createFromOptions(vision, {
    baseOptions: {
      // 구글이 호스팅하는 공식 모델 파일 (검증된 URL)
      modelAssetPath: "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task",
      delegate: "GPU"
    },
    runningMode: "VIDEO",
    numFaces: 1
  });
}

async function startFaceTracking(video, onResult) {
  const faceLandmarker = await setupFaceLandmarker();
  let lastVideoTime = -1;
  function loop() {
    if (video.currentTime !== lastVideoTime) {
      const result = faceLandmarker.detectForVideo(video, performance.now());
      onResult(result); // result.faceLandmarks[0]가 468개 좌표 배열
      lastVideoTime = video.currentTime;
    }
    requestAnimationFrame(loop);
  }
  loop();
}
</script>
```

`onResult`에서 받은 랜드마크 좌표로 Canvas에 점/선을 그리면 "실시간 얼굴 인식" 데모가 완성된다. 손 인식이 필요하면 같은 패턴으로 `HandLandmarker`를 쓴다 (모델 경로만 `hand_landmarker` 계열로 교체, 나머지 구조 동일).

## 필수 규칙

- 카메라 권한 거부/미지원 브라우저 대비 **반드시 fallback UI**(스크린샷, 설명 텍스트)를 넣는다. 발표 중 권한 팝업이 뜨거나 실패해서 화면이 깨지면 안 된다.
- HTTPS 또는 localhost가 아니면 `getUserMedia`가 아예 동작하지 않는다는 점을 감안해, `file://`로 직접 여는 경우를 대비한 안내 문구를 fallback에 포함한다.
