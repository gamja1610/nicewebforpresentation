# 기본값: 순수 Canvas 2D 시뮬레이션 (라이브러리 없음)

대부분의 "시뮬처럼 보이는" 배경/히어로 애니메이션은 라이브러리 없이 이걸로 충분하다. 프로젝트의 핵심 은유에 맞춰 파라미터(개수/속도/연결 여부/색)만 바꿔서 매번 다르게 만든다.

## 패턴 A — 떠다니는 파티클 (범용 배경)

```html
<canvas id="bg" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
<script>
function initParticleField(canvasId, { count = 80, color = "#7c5cff", connect = true, speed = 0.4 } = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; }
  window.addEventListener("resize", resize); resize();

  const pts = Array.from({ length: count }, () => ({
    x: Math.random() * w, y: Math.random() * h,
    vx: (Math.random() - 0.5) * speed, vy: (Math.random() - 0.5) * speed,
  }));

  function frame() {
    ctx.clearRect(0, 0, w, h);
    pts.forEach((p) => {
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0 || p.x > w) p.vx *= -1;
      if (p.y < 0 || p.y > h) p.vy *= -1;
      ctx.beginPath(); ctx.arc(p.x, p.y, 2, 0, Math.PI * 2);
      ctx.fillStyle = color; ctx.fill();
    });
    if (connect) {
      for (let i = 0; i < pts.length; i++) {
        for (let j = i + 1; j < pts.length; j++) {
          const dx = pts[i].x - pts[j].x, dy = pts[i].y - pts[j].y;
          const dist = Math.hypot(dx, dy);
          if (dist < 120) {
            ctx.globalAlpha = 1 - dist / 120;
            ctx.strokeStyle = color; ctx.beginPath();
            ctx.moveTo(pts[i].x, pts[i].y); ctx.lineTo(pts[j].x, pts[j].y); ctx.stroke();
            ctx.globalAlpha = 1;
          }
        }
      }
    }
    requestAnimationFrame(frame);
  }
  frame();
}
// 사용: initParticleField("bg", { count: 100, color: "#00e5c7", connect: true })
</script>
```

이 노드-연결 네트워크는 "여러 요소가 서로 통신/협력"하는 프로젝트(멀티에이전트, 분산시스템, 소셜)에 어울린다. `connect:false`로 끄면 단순 파티클 눈발 느낌.

## 패턴 B — 흐르는 데이터 스트림 (파이프라인/데이터 프로젝트용)

```js
function initDataStream(canvasId, { color = "#00e5c7" } = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  const w = canvas.width = window.innerWidth, h = canvas.height = window.innerHeight;
  const lanes = 6;
  const packets = Array.from({ length: 20 }, () => ({
    lane: Math.floor(Math.random() * lanes), x: Math.random() * w, speed: 2 + Math.random() * 3,
  }));
  function frame() {
    ctx.fillStyle = "rgba(10,10,15,0.25)"; ctx.fillRect(0, 0, w, h);
    packets.forEach((p) => {
      p.x += p.speed; if (p.x > w) p.x = -20;
      const y = (p.lane + 0.5) * (h / lanes);
      ctx.fillStyle = color; ctx.fillRect(p.x, y - 2, 16, 4);
    });
    requestAnimationFrame(frame);
  }
  frame();
}
```

이상탐지/모니터링 프로젝트라면 특정 패킷을 랜덤하게 붉은색으로 튀게 하는 식으로 변주한다 — 코드 구조는 동일, 색과 트리거 조건만 바꾼다.

## 패턴 D — 마우스 인터랙션 파티클 네트워크 (클래스형)

패턴 A의 업그레이드판 — 마우스가 다가가면 근처 파티클이 반응하는 느낌을 원할 때 쓴다. 단일 HTML 파일에 `<script>`(모듈 아님, 번들러 불필요)로 그대로 붙여넣고 `new ParticleNetwork("canvasId")`로 초기화한다. `import`/`export` 없이 클래스만 전역에 선언하는 형태로 써야 CDN 없이 바로 동작한다.

```html
<canvas id="bg"></canvas>
<script>
class ParticleNetwork {
  constructor(canvasId, { color = "124,92,255", maxDistance = 120, particleCount = 80 } = {}) {
    this.canvas = document.getElementById(canvasId);
    this.ctx = this.canvas.getContext("2d");
    this.color = color;
    this.maxDistance = maxDistance;
    this.particleCount = particleCount;
    this.particles = [];
    this.mouse = { x: null, y: null, radius: 150 };
    this.animId = null;
    this.init();
  }

  init() {
    this.resize();
    this._onResize = () => this.resize();
    this._onMove = (e) => {
      const rect = this.canvas.getBoundingClientRect();
      this.mouse.x = e.clientX - rect.left;
      this.mouse.y = e.clientY - rect.top;
    };
    window.addEventListener("resize", this._onResize);
    window.addEventListener("mousemove", this._onMove);

    for (let i = 0; i < this.particleCount; i++) {
      this.particles.push({
        x: Math.random() * this.canvas.width,
        y: Math.random() * this.canvas.height,
        vx: (Math.random() - 0.5) * 1.2,
        vy: (Math.random() - 0.5) * 1.2,
        radius: Math.random() * 2 + 1,
      });
    }
    this.animate();
  }

  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  }

  animate() {
    const { ctx, canvas, mouse } = this;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    this.particles.forEach((p, i) => {
      // 마우스 근처면 살짝 밀려나는 반응
      if (mouse.x != null) {
        const dx = p.x - mouse.x, dy = p.y - mouse.y;
        const dist = Math.hypot(dx, dy);
        if (dist < mouse.radius) {
          const force = (mouse.radius - dist) / mouse.radius;
          p.x += (dx / dist) * force * 1.5;
          p.y += (dy / dist) * force * 1.5;
        }
      }
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
      if (p.y < 0 || p.y > canvas.height) p.vy *= -1;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${this.color},0.8)`;
      ctx.fill();

      for (let j = i + 1; j < this.particles.length; j++) {
        const p2 = this.particles[j];
        const dist = Math.hypot(p.x - p2.x, p.y - p2.y);
        if (dist < this.maxDistance) {
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(p2.x, p2.y);
          ctx.strokeStyle = `rgba(${this.color},${1 - dist / this.maxDistance})`;
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    });

    this.animId = requestAnimationFrame(() => this.animate());
  }

  destroy() {
    cancelAnimationFrame(this.animId);
    window.removeEventListener("resize", this._onResize);
    window.removeEventListener("mousemove", this._onMove);
  }
}
// 사용: const net = new ParticleNetwork("bg", { color: "57,255,140" });
// 슬라이드를 벗어나 더 이상 안 보이면 net.destroy()로 리스너/루프 정리 (여러 팀 결과물 동시 실행 대비)
</script>
```

**중요(실제 사고로 확인된 버그): 반드시 `window.innerWidth/innerHeight`를 쓰고, `canvas.offsetWidth/offsetHeight`는 쓰지 않는다.** 슬라이드는 `.slide{display:none}`으로 시작해서 활성화될 때만 `display:flex`가 되는데, 캔버스가 속한 슬라이드가 아직 비활성 상태(`display:none`)일 때 `resize()`가 실행되면 `canvas.offsetWidth/offsetHeight`는 0을 반환한다. 그러면 캔버스 크기가 0×0으로 영원히 고정되어 **그 슬라이드로 넘어가도 아무것도 그려지지 않는다** (실제로 이 문제로 배경 애니메이션 전체가 안 보이는 사고가 있었다). 이 패턴(패턴 A/B/C/D)의 캔버스는 전부 `position:absolute;inset:0;width:100%;height:100%`인 **전체화면** 배경이므로 `window.innerWidth/innerHeight`를 써도 결과는 동일하고, 부모의 `display` 상태와 무관하게 항상 올바른 값을 반환한다. `destroy()`는 원본에 없던 리스너 정리를 추가한 것 — 슬라이드 전환 시 안 쓰는 인스턴스를 계속 돌리지 않기 위해서다.

**주의: 이건 전체화면 배경 캔버스에만 통하는 fix다.** 미니 그래프처럼 슬라이드 콘텐츠 안에 CSS로 크기가 정해지는(전체화면이 아닌) 캔버스는 `window` 크기를 쓰면 레이아웃이 깨진다 — 그 경우의 올바른 fix(슬라이드의 `slide-enter` 이벤트에서 재측정)는 [slide-engine.md](slide-engine.md)의 "슬라이드 안에 박힌 캔버스의 크기 버그" 절을 참고한다.

## 패턴 C — 웨이브/노이즈 필드 (수학적·유기적 느낌)

`Math.sin`/`Math.cos` 조합의 그리드 웨이브. 별도 라이브러리 없이 "수학적으로 정갈한" 느낌을 낼 때 p5.js 대신 이것부터 시도한다.

```js
function initWaveGrid(canvasId, { color = "#7c5cff", spacing = 24 } = {}) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext("2d");
  const w = canvas.width = window.innerWidth, h = canvas.height = window.innerHeight;
  let t = 0;
  function frame() {
    ctx.clearRect(0, 0, w, h);
    for (let x = 0; x < w; x += spacing) {
      for (let y = 0; y < h; y += spacing) {
        const r = 2 + 2 * Math.sin(x * 0.02 + t) * Math.cos(y * 0.02 + t);
        ctx.beginPath(); ctx.arc(x, y, Math.max(r, 0), 0, Math.PI * 2);
        ctx.fillStyle = color; ctx.fill();
      }
    }
    t += 0.03;
    requestAnimationFrame(frame);
  }
  frame();
}
```
