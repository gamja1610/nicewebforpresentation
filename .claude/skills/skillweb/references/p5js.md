# p5.js — 생성예술/수학적 시뮬레이션이 필요할 때

**언제 쓰나**: 플로킹(새떼), 노이즈 필드, 파동 간섭처럼 "규칙 기반으로 유기적으로 움직이는" 느낌이 프로젝트 은유와 맞을 때. 순수 Canvas(참고: `canvas-particles.md`)로 안 되는 정도의 복잡한 시뮬레이션에만 꺼내 쓴다 — 대부분은 canvas-particles.md 패턴으로 충분하다.

CDN: `<script src="https://cdn.jsdelivr.net/npm/p5@latest/lib/p5.min.js"></script>`

인스턴스 모드로 작성해서 한 페이지(슬라이드)에 여러 개 붙여도 전역 충돌이 안 나게 한다.

```html
<div id="p5-hero"></div>
<script src="https://cdn.jsdelivr.net/npm/p5@latest/lib/p5.min.js"></script>
<script>
new p5((p) => {
  let particles = [];
  const N = 150;

  p.setup = () => {
    const holder = document.getElementById("p5-hero");
    p.createCanvas(holder.offsetWidth, holder.offsetHeight).parent(holder);
    for (let i = 0; i < N; i++) {
      particles.push({ x: p.random(p.width), y: p.random(p.height), a: p.random(p.TWO_PI) });
    }
  };

  p.draw = () => {
    p.background(10, 10, 15, 40);
    particles.forEach((pt) => {
      const angle = p.noise(pt.x * 0.005, pt.y * 0.005, p.frameCount * 0.003) * p.TWO_PI * 2;
      pt.x += p.cos(angle) * 1.2;
      pt.y += p.sin(angle) * 1.2;
      if (pt.x < 0) pt.x = p.width; if (pt.x > p.width) pt.x = 0;
      if (pt.y < 0) pt.y = p.height; if (pt.y > p.height) pt.y = 0;
      p.noStroke(); p.fill(124, 92, 255, 180);
      p.circle(pt.x, pt.y, 3);
    });
  };

  p.windowResized = () => {
    const holder = document.getElementById("p5-hero");
    p.resizeCanvas(holder.offsetWidth, holder.offsetHeight);
  };
}, "p5-hero");
</script>
```

`p.noise()` 기반 흐름장이 "유기적/살아있는" 느낌을 가장 싸게 낼 수 있는 방법이다 — 색과 속도만 프로젝트 팔레트에 맞춰 바꾼다.
