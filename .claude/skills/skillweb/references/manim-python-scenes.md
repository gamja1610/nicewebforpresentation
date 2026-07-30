# Manim Python Scene 코드 패턴

이 파일은 `manim-web.md`의 `runManimScene(pySceneCode)`에 넣을 **Python Scene 코드**만 모아둔다. JS/Pyodide 연결 코드는 `manim-web.md`를 본다.

실제 소스: [MathItYT/manim](https://github.com/MathItYT/manim) (ManimCE를 브라우저용으로 포크). 실제 동작이 확인된 데모: [manim-web-demo/index.html](https://github.com/MathItYT/manim-web-demo/blob/main/index.html).

**공통 규칙**: 전부 `async def construct(self)` + `await self.play(...)` 형태로 쓴다 (README의 sync 예제는 실제 데모와 다르므로 따르지 않는다). `Text()`는 절대 쓰지 않는다 — `MathTex()`로 대체.

## ✅ 실제 검증됨 (데모에서 그대로 확인) — 원 + 좌표평면 + 수식

```python
class GeneratedScene(Scene):
    async def construct(self):
        circ = Circle()
        await self.play(Create(circ))
        plane = NumberPlane().add_coordinates()
        self.add(plane, circ)
        await self.play(Write(plane))
        eq = MathTex("x^2 + y^2 = 1").to_edge(UP)
        await self.play(Write(eq))
```

수학/기하 프로젝트의 기본값으로 이 패턴을 우선 시도한다.

## ⚠️ ManimCE 표준 API 기반, manim-web에서 미실측 — 반드시 브라우저에서 직접 테스트 후 사용

아래 두 패턴은 `Create`/`Write`/`animate`(검증됨)에 `Transform`/`FadeIn`/`FadeOut`/`Dot`/`Line`(ManimCE 표준이지만 이 포크에서 별도 검증 안 됨)을 섞은 것이다. 실패하면 즉시 `canvas-particles.md`로 폴백한다.

### 도형 변형 (알고리즘/상태 변화 표현)

```python
class GeneratedScene(Scene):
    async def construct(self):
        sq = Square(color=BLUE)
        await self.play(Create(sq))
        circ = Circle(color=PURPLE)
        await self.play(Transform(sq, circ))
        label = MathTex(r"\text{transform}").next_to(sq, UP)
        await self.play(Write(label))
        await self.play(FadeOut(sq), FadeOut(label))
```

### 노드 네트워크 (멀티에이전트/분산시스템 프로젝트용)

```python
class GeneratedScene(Scene):
    async def construct(self):
        nodes = [Dot(point=p, color=TEAL) for p in [LEFT * 3, UP * 2, RIGHT * 3, DOWN * 2]]
        lines = [Line(nodes[i].get_center(), nodes[(i + 1) % len(nodes)].get_center()) for i in range(len(nodes))]
        await self.play(*[Create(n) for n in nodes])
        await self.play(*[Create(l) for l in lines])
        await self.play(*[n.animate.scale(1.4) for n in nodes])
```

새 패턴을 시도할 땐 항상 "실제 검증됨" Scene을 베이스로 한 줄씩 바꿔가며 로컬에서 확인한다.
