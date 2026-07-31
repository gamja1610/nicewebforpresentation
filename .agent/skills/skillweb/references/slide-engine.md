# 슬라이드 엔진 — 모든 산출물의 공통 뼈대

모든 팀 결과물(`output/<team>.html`)은 이 엔진을 기반으로 만든다. 스크롤이 아니라 인덱스 기반으로 슬라이드를 전환한다.

```html
<style>
  html, body { margin:0; height:100%; overflow:hidden; background:#0a0a0f; }
  .slide {
    position:absolute; inset:0; display:none;
    width:100vw; height:100vh;
    flex-direction:column; align-items:center; justify-content:center;
  }
  .slide.active { display:flex; }
  .progress { position:fixed; bottom:24px; left:50%; transform:translateX(-50%); display:flex; gap:8px; z-index:10; }
  .progress .dot { width:8px; height:8px; border-radius:50%; background:#444; transition:background .3s; }
  .progress .dot.active { background:#fff; }
</style>

<div id="deck">
  <section class="slide" data-index="0">...Hero...</section>
  <section class="slide" data-index="1">...Problem...</section>
  <!-- ... -->
</div>
<div class="progress" id="progress"></div>

<script>
(function () {
  const slides = Array.from(document.querySelectorAll(".slide"));
  const progress = document.getElementById("progress");
  let current = -1; // -1(미활성)에서 시작 — 0으로 두면 goTo(0)이 "이미 현재 슬라이드"로 오인해 첫 슬라이드를 절대 활성화하지 못하는 치명적 버그가 생긴다. 실제로 이 버그 때문에 초기 화면이 통째로 검은 화면(display:none)이 되는 사고가 있었다.

  slides.forEach((_, i) => {
    const dot = document.createElement("div");
    dot.className = "dot";
    dot.addEventListener("click", () => goTo(i));
    progress.appendChild(dot);
  });

  function goTo(index) {
    if (index < 0 || index >= slides.length || index === current) return;
    if (current >= 0) {
      slides[current].classList.remove("active");
      progress.children[current].classList.remove("active");
    }
    current = index;
    const slide = slides[current];
    slide.classList.add("active");
    progress.children[current].classList.add("active");
    // 프로젝트별 등장 애니메이션 훅 — 슬라이드 요소에 data-anim 속성을 붙여두고 여기서 재생시킨다
    slide.dispatchEvent(new CustomEvent("slide-enter"));
  }

  window.addEventListener("keydown", (e) => {
    if (e.key === "ArrowRight" || e.key === " ") { e.preventDefault(); goTo(current + 1); }
    if (e.key === "ArrowLeft") goTo(current - 1);
  });

  // 클릭으로도 다음 슬라이드 (인터랙티브 요소는 stopPropagation으로 예외 처리)
  document.getElementById("deck").addEventListener("click", (e) => {
    if (e.target.closest("[data-no-advance]")) return;
    goTo(current + 1);
  });

  goTo(0); // current=-1에서 시작하므로 이제 정상적으로 첫 슬라이드를 활성화한다
})();
</script>
```

## 등장 애니메이션 훅 (GSAP)

CDN: `<script src="https://cdn.jsdelivr.net/npm/gsap@latest/dist/gsap.min.js"></script>`

```js
document.querySelectorAll(".slide").forEach((slide) => {
  slide.addEventListener("slide-enter", () => {
    const els = slide.querySelectorAll("[data-anim]");
    gsap.fromTo(els,
      { opacity: 0, y: 30 },
      { opacity: 1, y: 0, duration: 0.6, stagger: 0.12, ease: "power2.out" }
    );
  });
});
```

슬라이드 전환 자체의 트랜지션(페이드/스케일)은 `.slide`에 `transition: opacity .4s`를 주고 `active` 클래스 토글 타이밍을 맞추는 식으로 확장 가능 — 프로젝트 톤에 맞춰 조정한다.

## 슬라이드 안에 박힌(전체화면이 아닌) 캔버스의 크기 버그 — 실제 사고로 확인됨

`canvas.bg`처럼 `position:absolute;inset:0;width:100%;height:100%`인 **전체화면** 배경 캔버스는 `window.innerWidth/innerHeight`로 크기를 잡으면 되지만(`canvas-particles.md` 참고), 미니 그래프/예제 그래프처럼 **슬라이드 콘텐츠 안에 박혀서 CSS로 크기가 정해지는 캔버스**(`aspect-ratio` 박스 안 등)는 `window` 크기를 쓸 수 없다 — 그 컨테이너의 실제 렌더링 크기(`offsetWidth/offsetHeight`)를 알아야 한다.

문제는 이 슬라이드가 처음엔 `display:none`이라, 페이지 로드 시점에 딱 한 번 `offsetWidth`를 읽으면 0이 나오고, 그 캔버스의 `w,h`가 클로저 변수에 0으로 영원히 고정되어 **나중에 그 슬라이드로 넘어가도 아무것도 안 그려진다** (실제로 한 발표자료의 그래프 5개 중 히어로/클로징을 뺀 전부가 이 버그로 안 보이는 사고가 있었다). `window resize` 이벤트만 걸어두는 것으로는 해결이 안 된다 — 브라우저 창 크기 자체는 안 바뀌기 때문이다.

**고치는 법**: `resize()` 함수를 페이지 로드 시 1회 + `window resize`뿐 아니라, **그 캔버스가 속한 슬라이드의 `slide-enter` 이벤트에서도** 다시 호출한다. `slide-enter`가 발생하는 시점엔 이미 `.active` 클래스가 붙어 `display:flex`가 된 뒤이므로 `offsetWidth`가 항상 올바르게 잡힌다.

```js
function resize(){ w = canvas.width = canvas.offsetWidth; h = canvas.height = canvas.offsetHeight; }
window.addEventListener("resize", resize); resize();
const slideEl = canvas.closest(".slide");
if (slideEl) slideEl.addEventListener("slide-enter", resize); // 핵심: 이 한 줄이 없으면 비활성 슬라이드 안 캔버스는 계속 0×0
```

애니메이션 루프(`requestAnimationFrame`)가 클로저의 `w,h`를 매 프레임 참조하는 구조라면 이걸로 충분하다 — 다음 프레임부터 바로 올바른 크기로 그려진다. 만약 렌더 함수 자체가 매번 `canvas.offsetWidth`를 새로 읽는 구조(예: 성장/리빌 애니메이션)라면, 슬라이드가 비활성인 동안 실행되는 프레임에서 크기가 다시 0으로 덮어써지는 레이스 컨디션이 생길 수 있으니 `if(!canvas.offsetWidth) return;`으로 그 프레임의 렌더를 건너뛰게 가드한다.
