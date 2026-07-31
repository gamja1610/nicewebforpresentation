# 물리량에 실제로 연동된 시뮬레이션 (SKILL.md §1-5 전용 레퍼런스)

`canvas-particles.md`/`p5js.md`/`threejs.md`는 파티클 개수·속도·회전각이 "적당히 예뻐 보이는" 임의값이다. 이 파일은 다르다 — **여기 있는 함수들은 파라미터가 실제 물리량(진폭, 주파수, 위상차, 감쇠계수, 힘)이고, 그 값을 바꾸면 화면에 그려지는 현상 자체가 수식대로 바뀐다.** 강의자료·기술문서형 인풋(§5)에서 "계산 결과를 텍스트 카드로 나열"하는 대신 "그 현상이 실제로 일어나는 장면"을 만들 때 이 파일부터 시도한다. 여기 없는 현상은 이 파일의 패턴(값 → 위치/속도로 매핑하는 구조)을 본떠 새로 짜되, 반드시 실제 공식을 코드에 그대로 남긴다(예쁘게 보이려고 값을 왜곡하지 않는다).

## 패턴 A — 위상차 파동 + 왕복하는 에너지 입자 (전압/전류, 반사파, 정상파)

**언제 쓰나**: 두 신호(전압/전류, 입사파/반사파) 사이에 위상차나 진폭비가 있고, 그 어긋남 때문에 에너지가 왕복/중첩되는 현상을 설명할 때. SKILL.md §1-5의 "나쁜 예/좋은 예"에서 든 것과 동일한 상황.

```html
<canvas id="phase-wave" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
<script>
function initPhaseWave(canvasId, {
  freq = 1,           // Hz (실제 신호 주파수를 화면에 맞게 스케일한 값)
  ampA = 1, ampB = 0.6,          // 두 파형의 실제 진폭비 (예: V, I를 정규화한 값)
  phaseDeg = 30,       // 실제 위상차 θ (도)
  colorA = "#00e5c7", colorB = "#ff6b9d",
  showEnergyParticles = true,
} = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; }
  window.addEventListener("resize", resize); resize();

  const phase = (phaseDeg * Math.PI) / 180; // 도 → 라디안, 화면 표현이 아니라 실제 위상각
  const midY = () => h * 0.5;
  const cyclesOnScreen = 3;
  const omega = (2 * Math.PI * cyclesOnScreen) / w;

  // 에너지 입자: 두 파형이 어긋나는 만큼(=위상차) 순방향/역방향으로 갈리는 비율을 실제로 반영
  const forwardRatio = (Math.cos(phase) + 1) / 2; // θ=0(동상)이면 전부 정방향, θ=180°면 전부 반사
  const particles = showEnergyParticles
    ? Array.from({ length: 40 }, () => ({
        x: Math.random() * w,
        dir: Math.random() < forwardRatio ? 1 : -1,
        speed: 1.5 + Math.random() * 1.5,
        offset: Math.random() * 20 - 10,
      }))
    : [];

  let t = 0;
  function frame() {
    ctx.fillStyle = "rgba(10,10,15,0.25)";
    ctx.fillRect(0, 0, w, h);

    // 파형 A (기준 신호, 예: 전압)
    ctx.beginPath();
    for (let x = 0; x < w; x++) {
      const y = midY() + ampA * 60 * Math.sin(omega * x - t);
      x === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.strokeStyle = colorA; ctx.lineWidth = 2; ctx.stroke();

    // 파형 B (위상차 θ만큼 밀린 신호, 예: 전류)
    ctx.beginPath();
    for (let x = 0; x < w; x++) {
      const y = midY() + ampB * 60 * Math.sin(omega * x - t - phase);
      x === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.strokeStyle = colorB; ctx.lineWidth = 2; ctx.stroke();

    // 두 파형이 서로 어긋난 만큼(순간 위상차)을 에너지가 오가는 입자로 시각화
    particles.forEach((p) => {
      p.x += p.dir * p.speed;
      if (p.x > w) p.x = 0; if (p.x < 0) p.x = w;
      const y = midY() + p.offset;
      ctx.beginPath(); ctx.arc(p.x, y, 2, 0, Math.PI * 2);
      ctx.fillStyle = p.dir > 0 ? colorA : colorB;
      ctx.globalAlpha = 0.8; ctx.fill(); ctx.globalAlpha = 1;
    });

    t += 0.03 * freq;
    requestAnimationFrame(frame);
  }
  frame();
}
// 사용: initPhaseWave("phase-wave", { ampA: 1, ampB: 0.6, phaseDeg: 45 })
// phaseDeg를 슬라이드의 실제 예제값(예: 계산된 θ=36.87°)으로 그대로 넣으면
// "이 슬라이드만의 그래픽"이 된다 — 모든 팀이 phaseDeg=30 기본값을 그대로 쓰지 않도록 md의 실제 수치를 읽어서 넣는다.
</script>
```

`forwardRatio` 공식(`(cos θ + 1) / 2`)은 "위상차가 0이면 에너지가 전부 부하로 전달되고, 180°에 가까울수록 반사되어 되돌아온다"는 정상파 직관을 입자 방향 비율로 근사한 것이다 — 엄밀한 전력 전달 공식이 md에 따로 주어져 있다면 그 공식으로 `forwardRatio`를 교체한다.

## 패턴 B — 감쇠 진동 (RLC 과도응답, 스프링-댐퍼, 신호 감쇠)

**언제 쓰나**: `x(t) = A·e^(-ζωt)·cos(ωd·t + φ)` 형태의 감쇠/과도 응답이 있는 모든 것 — RLC 회로 과도응답, 스프링-질량-댐퍼, 진동 감쇠. 그래프로 그려서 끝내지 말고, 그 진폭만큼 실제로 흔들리는 오브젝트를 함께 그린다.

```html
<canvas id="damped-osc" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
<script>
function initDampedOscillator(canvasId, {
  zeta = 0.15,       // 실제 감쇠비 ζ (0<ζ<1이면 부족감쇠 — 진동하며 감쇠)
  omegaN = 2,        // 실제 고유각주파수 ωn (rad/s, 화면 속도로 스케일)
  amplitude = 80,    // 픽셀 스케일 (진폭의 시각적 크기)
  color = "#7c5cff",
} = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; }
  window.addEventListener("resize", resize); resize();

  const omegaD = omegaN * Math.sqrt(1 - zeta * zeta); // 실제 감쇠고유주파수
  const trail = [];
  let t = 0;

  function frame() {
    ctx.fillStyle = "rgba(10,10,15,0.15)";
    ctx.fillRect(0, 0, w, h);

    // 실제 감쇠 진동 공식 그대로 — 값을 예쁘게 보정하지 않는다
    const envelope = Math.exp(-zeta * omegaN * t);
    const x = amplitude * envelope * Math.cos(omegaD * t);
    const cx = w / 2, cy = h / 2;

    // 진동하는 질량(또는 회로의 순간 전류/전압)을 실제 오브젝트로 표시
    ctx.beginPath(); ctx.arc(cx + x, cy, 14, 0, Math.PI * 2);
    ctx.fillStyle = color; ctx.fill();

    // 스프링/연결선 (역학적 은유일 때만 — 회로면 이 선을 생략하고 숫자 라벨만 남긴다)
    ctx.beginPath(); ctx.moveTo(cx - w * 0.3, cy); ctx.lineTo(cx + x, cy);
    ctx.strokeStyle = "rgba(255,255,255,0.3)"; ctx.stroke();

    // 감쇠 포락선(envelope)을 궤적으로 남겨 "줄어드는 진폭"이 눈에 보이게
    trail.push({ x: cx + x, y: cy - t * 4 });
    if (trail.length > 200) trail.shift();
    ctx.beginPath();
    trail.forEach((p, i) => (i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y)));
    ctx.strokeStyle = color; ctx.globalAlpha = 0.5; ctx.stroke(); ctx.globalAlpha = 1;

    t += 0.02;
    if (envelope < 0.01) t = 0; // 다 감쇠되면 리셋해서 계속 반복 재생
    requestAnimationFrame(frame);
  }
  frame();
}
// 사용: initDampedOscillator("damped-osc", { zeta: 0.1, omegaN: 3 })
// zeta/omegaN은 md에 주어진 실제 회로/시스템 값(예: ζ=R/2·√(C/L))을 그대로 계산해서 넣는다.
</script>
```

## 패턴 C — 실제 필드 공식을 따라 흐르는 입자 (전류밀도, 힘의 장, 흐름장)

**언제 쓰나**: "장(field)"이 있고 그 장의 세기/방향이 위치에 따라 실제 공식으로 정해질 때(예: 두 전하 사이의 전기장, 자기장 코일 주변, 유체 속도장). `p5js.md`의 `p.noise()` 흐름장은 장식용 랜덤이라 이런 경우엔 안 맞는다 — 여기서는 입자의 속도를 **실제 필드 공식을 대입해서** 계산한다.

```html
<canvas id="field-flow" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
<script>
function initFieldFlow(canvasId, {
  sources = [{ x: 0.35, y: 0.5, strength: 1 }, { x: 0.65, y: 0.5, strength: -1 }], // 정규화 좌표(0~1) + 실제 부호/세기
  particleCount = 150,
  color = "#00e5c7",
} = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; }
  window.addEventListener("resize", resize); resize();

  function fieldAt(x, y) {
    // 실제 역제곱 법칙 형태의 필드 합성 (전기장/중력장과 동일한 구조: F ∝ q / r^2)
    let fx = 0, fy = 0;
    for (const s of sources) {
      const sx = s.x * w, sy = s.y * h;
      const dx = x - sx, dy = y - sy;
      const r2 = dx * dx + dy * dy + 400; // +400: 발산 방지용 소프트닝, 물리량 자체는 왜곡 안 함
      const f = (s.strength * 4000) / r2;
      fx += f * dx; fy += f * dy;
    }
    return { fx, fy };
  }

  const particles = Array.from({ length: particleCount }, () => ({
    x: Math.random() * w, y: Math.random() * h, life: Math.random(),
  }));

  function frame() {
    ctx.fillStyle = "rgba(10,10,15,0.12)";
    ctx.fillRect(0, 0, w, h);
    particles.forEach((p) => {
      const { fx, fy } = fieldAt(p.x, p.y); // 그 위치에서 실제 필드 벡터를 계산해 그대로 속도로 사용
      const speed = Math.hypot(fx, fy);
      p.x += fx; p.y += fy;
      p.life -= 0.005;
      if (p.life <= 0 || p.x < 0 || p.x > w || p.y < 0 || p.y > h) {
        p.x = Math.random() * w; p.y = Math.random() * h; p.life = 1;
      }
      ctx.beginPath(); ctx.arc(p.x, p.y, 1.5, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.globalAlpha = Math.min(0.9, speed * 0.5 + 0.2); // 필드가 센 곳일수록 밝게 — 장식이 아니라 실제 세기 반영
      ctx.fill(); ctx.globalAlpha = 1;
    });
    requestAnimationFrame(frame);
  }
  frame();
}
// 사용: initFieldFlow("field-flow", { sources: [{x:0.3,y:0.5,strength:1},{x:0.7,y:0.5,strength:-1}] })
// sources의 strength 부호/크기는 md에 주어진 실제 전하/극성 값을 그대로 반영한다 (둘 다 +면 반발, 부호가 다르면 흡인 궤적이 저절로 나온다).
</script>
```

## 패턴 D — 주파수 응답 스윕 (보드선도, 필터 특성)

**언제 쓰나**: "주파수를 스윕하며 이득/위상이 어떻게 변하는가"가 핵심 내용일 때 — 완성된 보드선도를 정적 이미지로 붙이지 않고, 스캔선이 주파수축을 따라 이동하며 그 순간의 실제 `H(jω)` 값을 계산해 곡선을 실시간으로 그려나가는 과정 자체를 시뮬레이션으로 보여준다.

```html
<canvas id="bode-sweep" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
<script>
function initBodeSweep(canvasId, {
  // H(jw) = 1 / (1 + j·w/wc)  같은 1차 저역통과 필터 예시 — 실제 전달함수로 교체
  magnitudeAt = (w) => 1 / Math.sqrt(1 + (w / 1000) ** 2),   // wc=1000 rad/s
  phaseAt = (w) => -Math.atan(w / 1000),                      // 라디안
  wMin = 10, wMax = 100000,   // 실제 스윕 범위 (rad/s)
  color = "#ff6b9d",
} = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; }
  window.addEventListener("resize", resize); resize();

  let sweepProgress = 0; // 0~1, log 스케일 주파수 진행률
  const points = [];

  function frame() {
    ctx.fillStyle = "#0a0a0f"; ctx.fillRect(0, 0, w, h);

    sweepProgress = (sweepProgress + 0.003) % 1;
    const logMin = Math.log10(wMin), logMax = Math.log10(wMax);
    const omega = Math.pow(10, logMin + sweepProgress * (logMax - logMin)); // 실제 각주파수 (log 스윕)
    const mag = magnitudeAt(omega); // 실제 전달함수 크기
    const px = sweepProgress * w;
    const py = h * 0.5 - mag * h * 0.4; // 이득을 실제 계산값 그대로 y좌표에 매핑

    if (sweepProgress < 0.01) points.length = 0; // 한 바퀴 돌면 궤적 리셋
    points.push({ x: px, y: py });

    ctx.beginPath();
    points.forEach((p, i) => (i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y)));
    ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();

    // 스윕선(현재 계산 중인 주파수 지점)
    ctx.beginPath(); ctx.moveTo(px, 0); ctx.lineTo(px, h);
    ctx.strokeStyle = "rgba(255,255,255,0.25)"; ctx.stroke();
    ctx.beginPath(); ctx.arc(px, py, 5, 0, Math.PI * 2);
    ctx.fillStyle = color; ctx.fill();

    requestAnimationFrame(frame);
  }
  frame();
}
// 사용: initBodeSweep("bode-sweep", { magnitudeAt: w => 1/Math.sqrt(1+(w/parseFloat(wc))**2) })
// magnitudeAt/phaseAt은 반드시 md에 주어진 실제 전달함수 H(jw)를 그대로 옮긴 함수여야 한다 — 임의의 곡선으로 대체하지 않는다.
</script>
```

## 공통 원칙

- **파라미터 이름에 물리 기호를 그대로 남긴다** (`zeta`, `omegaN`, `phaseDeg`, `sources[].strength`) — 나중에 md의 실제 수치를 대입하는 사람이 뭘 넣어야 할지 코드만 보고 알 수 있어야 한다.
- **"예쁘게 보정"이 필요하면 시각 스케일(픽셀 크기, 색)만 조절하고, 물리 공식 자체(지수감쇠, 역제곱, 위상각)는 절대 왜곡하지 않는다.** 왜곡하는 순간 이건 다시 "장식"으로 돌아간다.
- 위 네 패턴 모두 `window.innerWidth/innerHeight` 기반 전체화면 캔버스 — 슬라이드 내장형(작은 미니 그래프)으로 쓸 경우 [slide-engine.md](slide-engine.md)의 "슬라이드 안에 박힌 캔버스" 재측정 규칙을 반드시 함께 적용한다 (`canvas-particles.md`에 상세 설명).
- 여기 없는 현상(예: 열전달, 유체 난류, 양자역학적 확률분포)은 이 파일의 구조 — **"실제 공식 → 픽셀 좌표/속도/투명도로 직접 매핑"** — 를 그대로 본떠 새로 만든다. 그래프를 그리는 코드가 아니라 "그 공식이 매 프레임 실제로 계산되어 화면 위 무언가를 움직이는" 코드여야 이 원칙에 맞는다.
