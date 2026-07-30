# Three.js — 3D가 실제로 필요할 때만

**언제 쓰나**: 프로젝트가 공간/3D 데이터/게임/IoT 디바이스 형상처럼 3D 표현이 내용과 직결될 때만. 2D로 충분한 프로젝트에 과하게 쓰지 않는다 (로딩/성능 비용).

CDN(ES Module): `<script type="module">` 안에서 아래처럼 import.

```html
<canvas id="three-canvas" style="position:absolute;inset:0;"></canvas>
<script type="module">
import * as THREE from "https://cdn.jsdelivr.net/npm/three@latest/build/three.module.js";

function initHeroScene(canvasId) {
  const canvas = document.getElementById(canvasId);
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  // canvas.offsetWidth/offsetHeight는 이 캔버스가 속한 슬라이드가 아직 display:none이면 0을 반환한다
  // (실제 사고로 확인된 버그 — 상세: canvas-particles.md/slide-engine.md). 이 캔버스는 항상
  // position:absolute;inset:0;width:100%;height:100%인 전체화면 배경이므로 window 크기를 쓴다.
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.z = 6;

  // 예: 노드 네트워크를 3D 점군 + 라인으로 (프로젝트 은유에 맞게 지오메트리만 교체)
  const geometry = new THREE.IcosahedronGeometry(2, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x7c5cff, wireframe: true });
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  window.addEventListener("resize", () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  function animate() {
    mesh.rotation.x += 0.003;
    mesh.rotation.y += 0.004;
    renderer.render(scene, camera);
    requestAnimationFrame(animate);
  }
  animate();
  return { scene, camera, renderer, mesh };
}
</script>
```

슬라이드 전환으로 이 씬을 벗어날 때는 `renderer.setAnimationLoop(null)` 또는 애니메이션 루프를 멈추는 플래그를 둬서 안 보이는 곳에서 GPU를 계속 태우지 않게 한다 (여러 팀 결과물을 동시에 열어둘 수 있는 발표 환경 고려).

## 마우스 인터랙션 버전 (오브젝트가 커서를 부드럽게 따라 반응)

위 기본형에 마우스 위치를 lerp(선형보간)로 부드럽게 반영하고 싶을 때 쓴다. 지오메트리/머티리얼만 프로젝트 은유에 맞게 바꾸면 된다 — 아래는 예시로 `TorusKnotGeometry`를 썼다.

**주의**: 원본 아이디어는 `import * as THREE from 'three'`처럼 **bare specifier**(번들러 전제)로 되어 있었는데, 이 프로젝트는 번들러 없는 단일 HTML 파일이 목표이므로 위 기본형과 똑같이 **jsdelivr ESM URL을 그대로 import**해야 브라우저에서 바로 동작한다. 아래 코드는 그렇게 고친 버전이다.

```html
<canvas id="three-canvas" style="position:absolute;inset:0;"></canvas>
<script type="module">
import * as THREE from "https://cdn.jsdelivr.net/npm/three@latest/build/three.module.js";

function initInteractiveScene(canvasId) {
  const canvas = document.getElementById(canvasId);
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  // 전체화면 배경 캔버스이므로 window 크기를 쓴다 (이유: initHeroScene 위 주석 참고)
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.z = 4;

  // 예: 프로젝트 은유에 맞는 지오메트리로 교체 (여기서는 예시로 토러스 매듭)
  const geometry = new THREE.TorusKnotGeometry(1, 0.3, 100, 16);
  const material = new THREE.MeshStandardMaterial({ color: 0x6366f1, wireframe: true });
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  const light = new THREE.DirectionalLight(0xffffff, 2);
  light.position.set(2, 2, 5);
  scene.add(light, new THREE.AmbientLight(0xffffff, 0.5));

  const mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
  function onMouseMove(e) {
    // 마우스 좌표 정규화는 실제 렌더링된 박스 기준이어야 하므로 getBoundingClientRect()의
    // 실측 width/height를 쓴다(이건 mousemove가 실제로 발생한 시점이라 항상 0이 아니다).
    const rect = canvas.getBoundingClientRect();
    mouse.targetX = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
    mouse.targetY = -((e.clientY - rect.top) / rect.height - 0.5) * 2;
  }
  window.addEventListener("mousemove", onMouseMove);

  function onResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  }
  window.addEventListener("resize", onResize);

  let animId = null;
  function render() {
    mouse.x += (mouse.targetX - mouse.x) * 0.05;
    mouse.y += (mouse.targetY - mouse.y) * 0.05;

    mesh.rotation.x += 0.005 + mouse.y * 0.02;
    mesh.rotation.y += 0.005 + mouse.x * 0.02;

    renderer.render(scene, camera);
    animId = requestAnimationFrame(render);
  }
  render();

  return {
    stop() {
      if (animId) cancelAnimationFrame(animId);
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("resize", onResize);
      renderer.dispose();
    },
  };
}
// 사용: const scene = initInteractiveScene("three-canvas");
// 슬라이드를 벗어나면 scene.stop()으로 정리 (여러 팀 결과물 동시 실행 대비)
</script>
```

`MeshStandardMaterial`은 조명의 영향을 받는 재질이라 `DirectionalLight`/`AmbientLight`가 반드시 필요하다 (기본형의 `MeshBasicMaterial`은 조명 없이도 보이지만 입체감이 없다). 마우스 반응 강도(`0.02`)와 기본 회전 속도(`0.005`)는 프로젝트 톤에 맞게 조절한다.

## 회전 텀블링 지오메트리 필드 (여러 조각이 각자 회전 + 카메라가 여러 각도로 서서히 이동)

**언제 쓰나**: 하드웨어/부품 구성, 데이터 조각, 모듈형 시스템처럼 "여러 개의 독립된 덩어리가 모여 하나를 이룬다"는 은유가 맞을 때. 2D 플랫 일러스트 대신 실제 입체감 있는 3D 오브젝트가 여러 구도에서 보여야 하는 프로젝트(하드웨어 부품, 3D 프린팅, 물리 시뮬레이션 등)에 적합 — 단일 오브젝트가 제자리에서만 도는 위 기본형과 달리, **여러 개의 조각이 각자 다른 속도로 회전**하고 **카메라 자체도 궤도를 따라 서서히 움직여서** 매 순간 다른 각도의 구도가 보이는 게 핵심이다.

```html
<canvas id="three-canvas" style="position:absolute;inset:0;"></canvas>
<script type="module">
import * as THREE from "https://cdn.jsdelivr.net/npm/three@latest/build/three.module.js";

function initTumblingChunks(canvasId, { count = 7, colors = [0x39ff8c, 0xffb020, 0x2a3d33] } = {}) {
  const canvas = document.getElementById(canvasId);
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // 전체화면 배경 캔버스이므로 window 크기를 쓴다 (이유: initHeroScene 위 주석 참고)
  renderer.setSize(window.innerWidth, window.innerHeight);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);

  const light = new THREE.DirectionalLight(0xffffff, 2.2);
  light.position.set(3, 4, 5);
  scene.add(light, new THREE.AmbientLight(0xffffff, 0.4));

  // 지오메트리 종류를 섞어서 "여러 부품이 모인" 느낌을 낸다 — 프로젝트 부품 수/성격에 맞게 교체
  const geometries = [
    () => new THREE.BoxGeometry(1, 1, 1),
    () => new THREE.IcosahedronGeometry(0.7, 0),
    () => new THREE.OctahedronGeometry(0.7, 0),
    () => new THREE.TorusGeometry(0.5, 0.2, 8, 16),
  ];

  const chunks = Array.from({ length: count }, (_, i) => {
    const geometry = geometries[i % geometries.length]();
    const material = new THREE.MeshStandardMaterial({
      color: colors[i % colors.length], flatShading: true, metalness: 0.2, roughness: 0.5,
    });
    const mesh = new THREE.Mesh(geometry, material);
    const radius = 2.2 + Math.random() * 1.4;
    const angle = (i / count) * Math.PI * 2;
    mesh.position.set(Math.cos(angle) * radius, (Math.random() - 0.5) * 2.4, Math.sin(angle) * radius);
    scene.add(mesh);
    return {
      mesh,
      spin: { x: (Math.random() - 0.5) * 0.02, y: (Math.random() - 0.5) * 0.02, z: (Math.random() - 0.5) * 0.02 },
    };
  });

  let orbitAngle = 0;
  function onResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  }
  window.addEventListener("resize", onResize);

  let animId = null;
  function animate() {
    orbitAngle += 0.0016; // 카메라가 씬 주위를 서서히 궤도 이동 — 이게 "여러 각도에서 보이는" 핵심
    camera.position.set(Math.cos(orbitAngle) * 7, 2 + Math.sin(orbitAngle * 0.7) * 1.5, Math.sin(orbitAngle) * 7);
    camera.lookAt(0, 0, 0);

    chunks.forEach(({ mesh, spin }) => {
      mesh.rotation.x += spin.x; mesh.rotation.y += spin.y; mesh.rotation.z += spin.z;
    });

    renderer.render(scene, camera);
    animId = requestAnimationFrame(animate);
  }
  animate();

  return {
    stop() {
      if (animId) cancelAnimationFrame(animId);
      window.removeEventListener("resize", onResize);
      renderer.dispose();
    },
  };
}
// 사용: const scene = initTumblingChunks("three-canvas", { count: 8, colors: [0x..., 0x...] });
</script>
```

조각 개수(`count`)는 프로젝트의 실제 구성요소 수(부품 개수, 모듈 개수 등)에 맞춰 정하면 "장식"이 아니라 "그 프로젝트의 실제 구조"로 읽힌다. `colors`는 프로젝트 팔레트의 포인트 컬러 1~2개 + 무채색 하나 조합을 권장(`visual-language.md`의 도메인별 팔레트 표 참고). 궤도 이동 속도(`orbitAngle` 증분)가 너무 빠르면 어지럽고 너무 느리면 정지된 것처럼 보이므로 `0.001~0.003` 범위에서 조절한다.

## 한 덱에 3D 씬이 여러 개 있을 때 — 레지스트리로 lazy init + stop/dispose

**왜 필요한가**: 위 `initHeroScene`/`initInteractiveScene`/`initTumblingChunks`를 슬라이드마다 하나씩 붙여서 한 덱에 3D 씬이 5~6개가 되면, 페이지 로드 시 전부 즉시 `renderer`를 생성해 WebGL 컨텍스트를 동시에 여러 개 띄우게 된다. 브라우저는 동시에 열 수 있는 WebGL 컨텍스트 수에 제한이 있고, 노트북 GPU 기준으로 여러 씬이 동시에 `requestAnimationFrame`을 돌리면 버벅인다 — 실제로 한 발표자료가 이 이유로 뒷 슬라이드로 갈수록 눈에 띄게 느려진 사고가 있었다.

**고치는 법**: 씬 생성 함수를 즉시 실행하지 않고, `slide-engine.md`의 `slide-enter`/이탈 시점에 맞춰 그 슬라이드가 활성화될 때만 초기화(lazy init)하고, 다른 슬라이드로 넘어가면 즉시 `stop()`으로 정지시킨다. 위 세 함수는 전부 이미 `stop()`(또는 반환 객체)을 제공하므로 그대로 재사용 가능 — `initHeroScene`만 `stop()`이 없으니 `initInteractiveScene`처럼 `{ stop(){...} }`을 반환하도록 맞춰서 쓴다.

```js
// 슬라이드 인덱스(data-index) → 3D 씬 초기화 함수 매핑. 페이지 로드 시 아무것도 실행하지 않는다.
const sceneRegistry = new Map();
function registerScene(slideIndex, canvasId, initFn, opts) {
  sceneRegistry.set(slideIndex, { canvasId, initFn, opts, instance: null });
}

let activeSceneIndex = null;
function activateScene(slideIndex) {
  // 이전에 켜져 있던 3D 씬은 무조건 먼저 끈다 — "한 번에 하나만 활성화" 규칙
  if (activeSceneIndex !== null && activeSceneIndex !== slideIndex) {
    const prev = sceneRegistry.get(activeSceneIndex);
    if (prev && prev.instance) {
      prev.instance.stop();
      prev.instance = null;
    }
  }
  const entry = sceneRegistry.get(slideIndex);
  if (!entry) { activeSceneIndex = null; return; } // 이 슬라이드엔 3D 씬이 없음 (2D 패턴만 쓰는 슬라이드)
  if (!entry.instance) {
    entry.instance = entry.initFn(entry.canvasId, entry.opts); // 이 시점에 처음 WebGLRenderer 생성
  }
  activeSceneIndex = slideIndex;
}

// 등록은 한 번만, 각 슬라이드의 실제 3D 씬 함수와 캔버스 id로 교체
registerScene(0, "hero-canvas", initInteractiveScene, { /* ... */ });
registerScene(3, "chunks-canvas", initTumblingChunks, { count: 6 });

// slide-engine.md의 goTo() 안 slide.dispatchEvent(new CustomEvent("slide-enter")) 직후에 연결
document.querySelectorAll(".slide").forEach((slide, i) => {
  slide.addEventListener("slide-enter", () => activateScene(i));
});
```

핵심 규칙: **`instance`가 `null`이 아닌 씬은 항상 최대 하나**여야 한다. 텍스트만 있거나 2D `canvas-particles.md` 패턴만 쓰는 슬라이드는 `sceneRegistry`에 아예 등록하지 않으면 되므로, 3D는 핵심 슬라이드 몇 개에만 쓰고 나머지는 가벼운 2D로 채우는 §4의 권장 비율과도 자연스럽게 맞는다.

**개수가 실제 구성요소 수(3~5개)라 화면이 허전하면** — 억지로 조각 수를 늘려 은유를 깨지 말고, 대신 `canvas-particles.md` 패턴 A(떠다니는 파티클)를 배경에 한 겹 더 깐다. 이 3D 씬 캔버스보다 DOM에서 먼저 오는 별도 `<canvas>`(2D context)에 `count:30~50, connect:false`(연결선은 끄면 O(n²) 비교가 없어져 더 가볍다) 정도로 깔면, WebGL 렌더러의 `alpha:true` 투명 배경 사이로 비쳐서 화면이 채워진다. 3D 렌더링(GPU)과 2D 파티클(CPU, 가벼움)은 서로 다른 리소스를 쓰므로 부하가 거의 안 늘어난다 — 파티클 개수를 80 이상으로 올리거나 `connect:true`를 다인원(80+)에 쓰는 것만 피하면 된다.
