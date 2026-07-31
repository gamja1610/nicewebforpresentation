# 스펙터클 이펙트 — 임팩트 순간을 위한 재사용 코드

**언제 쓰나**: §1에서 뽑은 "시그니처 스펙터클 모먼트"(핵심 동작을 문자 그대로 재연하는 임팩트 장면)를 구현할 때. 아래 4가지 빌딩블록을 조합하면 대부분의 "쇼크"급 연출이 된다 — 도메인에 맞게 색상·좌표·트리거 조건만 바꾸고, 이펙트 자체를 매번 새로 설계하지 않는다.

## 1. 화면 흔들림 (Screen Shake)

```css
.slide.shake{animation:shakeKey .22s linear;}
@keyframes shakeKey{
  0%{transform:translate(0,0);} 15%{transform:translate(-10px,6px);} 30%{transform:translate(8px,-8px);}
  45%{transform:translate(-7px,5px);} 60%{transform:translate(6px,-4px);} 75%{transform:translate(-3px,2px);}
  100%{transform:translate(0,0);}
}
```

```js
function triggerShake(el) {
  if (!el) return;
  el.classList.remove("shake");
  void el.offsetWidth; // 리플로우 강제 → 이미 재생 중이어도 애니메이션 재시작
  el.classList.add("shake");
}
```

`el`은 보통 이펙트가 일어나는 `.slide` 컨테이너(캔버스와 텍스트를 함께 흔든다). 캔버스 안에서 트리거한다면 `canvas.closest(".slide")`로 얻는다.

## 2. 임팩트 플래시 (색 번쩍임)

```html
<div class="fire-flash" id="flash-X"></div>
```

```css
.fire-flash{position:absolute;inset:0;pointer-events:none;z-index:0;opacity:0;
  background:radial-gradient(circle at 60% 78%, rgba(255,200,120,.55), rgba(255,178,32,0) 55%);}
.fire-flash.on{animation:flashKey .22s ease-out;}
@keyframes flashKey{0%{opacity:.9;}100%{opacity:0;}}
```

```js
function triggerFlash(el) {
  if (!el) return;
  el.classList.remove("on");
  void el.offsetWidth;
  el.classList.add("on");
}
```

색은 도메인에 맞게 바꾼다 — 경보/이상탐지는 붉은색(`rgba(255,60,60,...)`), 헬스케어 스파이크는 청록, 핀테크 급등은 골드, 발사/충격류는 앰버. `z-index`는 배경 캔버스보다 위, 텍스트 콘텐츠(보통 `z-index:1`)보다는 아래로 둬서 플래시가 터져도 텍스트 가독성을 해치지 않는다.

## 3. Canvas 임팩트 버스트 (머즐 플래시 / 스파크 / 충격파)

좌표 `(x, y)`와 진행률(0~1)만 넘기면 방사형 버스트 + 확장하는 충격파 링을 그려주는 범용 함수.

```js
function drawImpactBurst(ctx, x, y, progress, color = "255,178,32") {
  if (progress < 0.35) {
    const p = progress / 0.35;
    const r = 26 * (1 - p) + 4;
    const grad = ctx.createRadialGradient(x, y, 0, x, y, r + 6);
    grad.addColorStop(0, "rgba(255,255,255,.95)");
    grad.addColorStop(0.5, `rgba(${color},.8)`);
    grad.addColorStop(1, `rgba(${color},0)`);
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fillStyle = grad; ctx.fill();
  }
  if (progress < 1) {
    const ringR = progress * 46;
    ctx.strokeStyle = `rgba(${color},${Math.max(0, 0.5 - progress * 0.5)})`;
    ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(x, y, ringR, 0, Math.PI * 2); ctx.stroke();
  }
}
// 사용: fireT를 0에서 늘려가며 매 프레임 drawImpactBurst(ctx, x, y, fireT/0.45, "57,255,140") 호출
```

## 4. 파편/스파크 파티클 (버스트 잔상)

```js
function spawnBurstParticles(list, x, y, { count = 16, speed = 40, spread = Math.PI * 2 } = {}) {
  for (let i = 0; i < count; i++) {
    const a = -Math.PI / 2 + (Math.random() - 0.5) * spread;
    list.push({
      x, y,
      vx: Math.cos(a) * (speed * 0.5 + Math.random() * speed),
      vy: Math.sin(a) * (speed * 0.5 + Math.random() * speed) - 10,
      life: 0, maxLife: 0.9 + Math.random() * 0.5,
    });
  }
}

function updateAndDrawBurstParticles(ctx, list, dt, color = "180,190,185") {
  for (let i = list.length - 1; i >= 0; i--) {
    const p = list[i];
    p.life += dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vy -= 6 * dt;
    if (p.life >= p.maxLife) { list.splice(i, 1); continue; }
    const a = Math.max(0, 1 - p.life / p.maxLife) * 0.4;
    ctx.beginPath(); ctx.arc(p.x, p.y, 4 + p.life * 10, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(${color},${a})`; ctx.fill();
  }
}
```

연기/디브리는 회색(`180,190,185`), 스파크는 도메인 포인트 컬러, 경고/위험은 붉은색으로 바꿔 쓴다.

## 5. 조합 패턴 (권장 루프 구조)

```js
let impactT = -1; // -1이면 비활성
const debris = [];

function onImpactMoment(x, y) {
  impactT = 0;
  spawnBurstParticles(debris, x, y);
  triggerShake(canvas.closest(".slide"));
  triggerFlash(document.getElementById("flash-X"));
}

// requestAnimationFrame 루프 안에서 매 프레임:
if (impactT >= 0) {
  impactT += dt;
  drawImpactBurst(ctx, x, y, Math.min(impactT / 0.45, 1));
  if (impactT > 1.2) impactT = -1;
}
updateAndDrawBurstParticles(ctx, debris, dt);
```

**트리거 조건은 프로젝트의 핵심 동작에 맞게 정한다** — 예: 하드웨어가 반복적으로 어떤 동작(발사/충돌/변형)을 한다면 몇 초 주기 반복 루프, "이상 탐지" 같은 프로젝트라면 무작위 타이밍, "결과가 나오는 순간"을 강조하고 싶다면 슬라이드 진입(`slide-enter`) 시 한 번만 재생한다. 임팩트가 일어나는 좌표(`x, y`)도 실제로 그리고 있는 장면(캐릭터/장치/그래프의 특정 지점)에서 뽑아내야 한다 — 화면 중앙에 뜬금없이 버스트만 튀어나오면 안 된다.
