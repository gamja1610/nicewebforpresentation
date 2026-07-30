# manim-web — 브라우저에서 실제 Manim 코드 실행하기

**언제 쓰나**: 프로젝트가 수학/알고리즘/기하학을 다루고, Manim 특유의 벡터 도형·수식 애니메이션(원, 좌표평면, MathTex 수식이 그려지고 변형되는 느낌)이 프로젝트 정체성과 직접 관련될 때. 이 경우 아래 코드를 기반으로 **manim-web 사용을 시도한다** (JS Canvas로 대충 흉내내지 말고).

Pyodide(WASM Python 런타임) 위에서 `micropip`으로 `manim-web` 패키지를 설치하고, ManimCE 문법 그대로 Scene을 작성해 `<canvas>`에 렌더링한다.

**출처(실제 확인함)**:
- 패키지: [manim-web · PyPI](https://pypi.org/project/manim-web/)
- 실제 소스 코드: [MathItYT/manim](https://github.com/MathItYT/manim) — ManimCE를 웹용으로 포크한 것 (3Blue1Brown의 원본 manim이 아니라 **ManimCommunity/manim의 포크**)
- 실제 동작하는 데모: [MathItYT/manim-web-demo](https://github.com/MathItYT/manim-web-demo/blob/main/index.html) (라이브: https://mathityt.github.io/manim-web-demo/)

## ⚠️ README 예제와 실제 동작 코드가 다름 — async 버전을 신뢰할 것

`MathItYT/manim`의 README는 이렇게 **동기(sync)** 코드를 예시로 보여준다:

```python
from manim import *

class MyScene(Scene):
    def construct(self):
        square = Square()
        self.add(square)
        self.wait(1)
        self.play(square.animate.rotate(PI / 4))
        self.wait(1)
```

하지만 같은 README에 "`self.construct`, `self.play`, `self.wait` 같은 다수 연산이 비동기라서 `async`/`await`를 써야 한다"고도 적혀 있고, **실제로 브라우저에서 돌아가는 걸 확인한 코드**(`manim-web-demo`의 `index.html`)는 아래처럼 전부 `async def construct` + `await self.play(...)` 형태다. 이 문서에서는 **실제로 검증된 async 패턴만** 사용한다 — README의 sync 예제는 그대로 베끼면 안 될 수 있다.

## 알려진 제약

- **`Text` mobject 사용 불가** (아직 미구현, README에 명시됨) — `Tex()`/`Text()` 대신 **`MathTex()`**만 쓴다. 일반 텍스트도 `MathTex(f"\\text{{{내용}}}")`처럼 우회한다.
- 수식 렌더링은 시스템 LaTeX가 아니라 **MathJax**로 처리됨 (그래서 HTML에 MathJax `<script>`를 같이 넣어야 함 — 아래 예제 참고).
- `Axes`, `NumberPlane`, `ValueTracker`, `always_redraw` 등 ManimCE의 다른 기능은 포크 구조상 동작할 가능성이 높지만 **공식적으로 검증된 건 데모의 `Circle`/`NumberPlane`/`MathTex`/`Create`/`Write`뿐**이다. 다른 기능을 쓸 땐 반드시 로컬에서 먼저 테스트하고, 안 되면 canvas-particles.md 패턴으로 즉시 폴백한다.
- Pyodide 자체 로딩(수십 MB WASM)에 시간이 걸림 — 슬라이드 진입 시 로딩 스피너/스켈레톤을 반드시 보여주고, 이 슬라이드만 로딩이 느릴 수 있음을 감안해 다른 슬라이드보다 먼저 프리로드를 시작한다.
- 베타 단계 패키지 — 실패 시 정적 이미지나 CSS 애니메이션으로 즉시 폴백할 수 있게 `try/catch`로 감싼다.

## 최소 동작 예제 (실제 검증된 코드, 그대로 이식해서 슬라이드용으로 축소)

```html
<div id="manim-container">
  <canvas id="manim-canvas" width="1920" height="1080" style="width:100%;height:auto;display:block;"></canvas>
</div>
<script src="https://cdn.jsdelivr.net/pyodide/v0.27.7/full/pyodide.js"></script>
<!-- MathTex 렌더링에 필요 (LaTeX 대신 MathJax 사용) -->
<script type="text/javascript">
  window.MathJax = { loader: { load: ['output/svg', 'ui/menu'] }, tex: { packages: ['base', 'require'] } };
</script>
<script type="text/javascript" id="MathJax-script" defer
  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
<script type="text/javascript">
async function runManimScene(pySceneCode) {
  const canvas = document.getElementById("manim-canvas");
  const ctx = canvas.getContext("2d");

  let pyodide = await loadPyodide();
  await pyodide.loadPackage("micropip");
  await pyodide.runPythonAsync(`
import micropip
await micropip.install("manim-web")
`);

  // Manim이 프레임마다 쏘는 draw call을 Canvas 2D로 그대로 그려주는 리스너
  canvas.addEventListener("frame-emit", async (event) => {
    for (const data of event.detail) {
      if (data.type === "VMobjectData") {
        ctx.setTransform(...data.transform);
        ctx.beginPath();
        for (const subpath of data.points) {
          const [sx, sy] = subpath[0][0];
          ctx.moveTo(sx, sy);
          for (const [, [x1, y1], [x2, y2], [x3, y3]] of subpath) {
            ctx.bezierCurveTo(x1, y1, x2, y2, x3, y3);
          }
        }
        const [fr, fg, fb, fa] = data.fill_rgbas[0] ?? [1, 1, 1, 0];
        ctx.fillStyle = `rgba(${fr * 255},${fg * 255},${fb * 255},${fa})`;
        ctx.fill();
        const [sr, sg, sb, sa] = data.stroke_rgbas[0] ?? [1, 1, 1, 0];
        if (data.stroke_width > 0) {
          ctx.strokeStyle = `rgba(${sr * 255},${sg * 255},${sb * 255},${sa})`;
          ctx.lineWidth = data.stroke_width / 100;
          ctx.stroke();
        }
      } else if (data.type === "BackgroundData") {
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        const [r, g, b] = data.background_color;
        ctx.fillStyle = `rgba(${r * 255},${g * 255},${b * 255},${data.background_opacity})`;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
      }
    }
  });

  await pyodide.runPythonAsync(`
from manim import *
from js import document

${pySceneCode}

scene = GeneratedScene()
scene.init_element(document.getElementById("manim-canvas"), "frame-emit")
await scene.render()
`);
}

// 사용 예: 프로젝트에 맞는 Scene을 문자열로 넘긴다
runManimScene(`
class GeneratedScene(Scene):
    async def construct(self):
        circ = Circle()
        await self.play(Create(circ))
        plane = NumberPlane().add_coordinates()
        self.add(plane, circ)
        await self.play(Write(plane))
        eq = MathTex("x^2 + y^2 = 1").to_edge(UP)
        await self.play(Write(eq))
`);
</script>
```

이 슬라이드가 활성화되는 시점(slide-enter)에 `runManimScene(...)`을 호출하고, 다른 슬라이드로 넘어가면 `pyodide` 인스턴스는 재사용하거나(권장, 재로딩 비용 큼) 최소한 애니메이션 루프는 멈춘다.

## Python Scene 코드

`runManimScene(pySceneCode)`의 `pySceneCode` 자리에 넣을 실제 Manim Python 코드(3Blue1Brown 계열 ManimCE 문법)는 별도 파일로 분리했다 → **[references/manim-python-scenes.md](manim-python-scenes.md)** 를 본다. 프로젝트 성격에 맞는 Scene 패턴을 그 파일에서 골라 위 `pySceneCode` 자리에 그대로 넣으면 된다.
