# 타이포그래피 — 실제 관찰한 패턴 + 재사용 코드

`visual-ref/typography/`의 한국 모션그래픽/홍보영상 레퍼런스 5개를 샘플링해서 관찰했다. 공통적으로 나온 건 "극단적인 크기 대비"와 "같은 텍스트를 두 번 겹쳐 찍는 트릭"이다.

## 1. 폰트

한글 대응이 되는 굵은 고딕 계열이 전부에서 쓰였다(브랜드마다 다르지만 톤이 통일됨 — Pretendard/Noto Sans KR 계열). CDN으로 바로 쓴다.

```html
<link rel="stylesheet" as="style" crossorigin
  href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<style>
  body { font-family: "Pretendard", -apple-system, "Malgun Gothic", sans-serif; }
  .headline { font-weight: 900; } /* Black */
  .caption   { font-weight: 500; } /* Medium */
</style>
```

**크기 대비 규칙**: 헤드라인과 캡션의 폰트 크기 비율이 관찰된 모든 레퍼런스에서 3~5배 차이 났다 (예: 헤드라인 `clamp(48px, 8vw, 120px)` vs 캡션 `clamp(14px, 1.5vw, 20px)`). 중간 크기를 어중간하게 쓰지 않는다.

## 2. 면+외곽선 겹침 텍스트 (반복 관찰됨 — Hero 타이틀 기본기)

"NOV 28TH" 광고와 이전에 본 "BREAKOUT" 브랜드 카드에서 독립적으로 반복 관찰된 패턴: 같은 텍스트를 굵은 면(solid)과 얇은 외곽선(outline)으로 번갈아 쌓아서 입체감/에너지를 낸다.

```html
<div class="stack-type">
  <span class="solid">HACKATHON</span>
  <span class="outline">HACKATHON</span>
</div>
<style>
.stack-type { position: relative; font-weight: 900; font-size: clamp(40px, 7vw, 100px); line-height: 1.15; }
.stack-type .solid { color: #fff; display: block; }
.stack-type .outline {
  display: block; color: transparent;
  -webkit-text-stroke: 1.5px rgba(255,255,255,.55);
  margin-top: -0.15em; /* 살짝 겹치게 */
  transform: translateX(0.06em);
}
</style>
```

## 3. 스크롤링 마퀴 테두리 텍스트 (세일/이벤트 톤)

화면 네 변을 따라 같은 문구가 반복 스크롤되는 프레임 — "임팩트/긴급성"을 줄 때 쓴다. 슬라이드 전체를 감싸는 장식 테두리로 적합.

```html
<div class="marquee-border"><div class="marquee-track">
  <span>HACKATHON DEMO DAY&nbsp;&nbsp;</span><span>HACKATHON DEMO DAY&nbsp;&nbsp;</span>
</div></div>
<style>
.marquee-border { position: absolute; top:0; left:0; width:100%; overflow:hidden; white-space:nowrap;
  background:#7c5cff; color:#fff; font-weight:800; padding:6px 0; }
.marquee-track { display:inline-block; animation: marqueeKey 12s linear infinite; }
@keyframes marqueeKey { from{transform:translateX(0);} to{transform:translateX(-50%);} }
</style>
```

## 4. 하단 캡션 바 (거의 모든 레퍼런스에서 반복)

화면 하단에 반투명/불투명 배경 위에 굵은 텍스트로 한 줄 설명을 얹는 컨벤션 — award 릴의 "제작자 크레딧", 이 타이포그래피 영상들의 "설명 자막" 모두 같은 구조였다.

```html
<div class="caption-bar">반려동물 영양 데이터를 실시간으로 분석합니다</div>
<style>
.caption-bar {
  position:absolute; left:24px; bottom:24px; max-width:80%;
  background:rgba(0,0,0,.55); color:#fff; font-weight:600;
  padding:10px 16px; border-radius:4px; font-size: clamp(14px, 1.6vw, 20px);
}
</style>
```

팀명/팀원 크레딧(Closing 슬라이드)에도 이 컨벤션을 그대로 쓴다.

## 5. 키워드 하이라이트 바 (설명형 콘텐츠)

본문 텍스트 중 핵심 구문만 색이 있는 배경 바 위에 얹어서 강조 — Define/Problem 같은 설명 슬라이드에 적합.

```html
<p><mark class="kw">해결의 기회를 내포하는 문제 정의</mark></p>
<style>.kw { background:#ff6b57; color:#fff; padding:2px 8px; border-radius:2px; font-weight:700; }</style>
```

## 6. 로고/타이틀 리빌 시퀀스

단색 배경 화면 전체 전환 → 중앙에 아이콘 마크 등장 → 워드마크가 옆에 스태거로 붙는 순서가 여러 레퍼런스에서 동일하게 나타남. `slide-engine.md`의 GSAP stagger로 그대로 구현 가능:

```js
gsap.timeline()
  .from(".logo-mark", { scale: 0, opacity: 0, duration: 0.5, ease: "back.out(2)" })
  .from(".logo-word", { opacity: 0, x: -12, duration: 0.4 }, "-=0.15");
```
