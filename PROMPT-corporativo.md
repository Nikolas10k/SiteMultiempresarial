# Recreate this site as a single HTML file: Multiempresarial — Centro Empresarial em Brasília

You are an expert creative front-end developer. Produce a single self-contained `index.html` that reproduces the project below exactly — same layout, sections, visuals, motion, and interaction. Pure HTML/CSS/JS in one file: no build step, no framework, no bundler. Use ES modules with a CDN importmap for the one library used (Lenis, for smooth scroll). Hardcode every value given here as a fixed constant. Reproduce all spring/text animation with plain JS (a tiny rAF spring helper) and CSS — no React, no @react-spring, no spring-text-engine.

**All visible copy is Brazilian Portuguese (`<html lang="pt-BR">`) and must be used verbatim.** Do not invent facts (numbers of rooms, floors, years, prices, testimonials, names of people). Everything factual in this spec comes from the building's current website.

## What it is

A single-screen-then-scroll institutional landing page for the **Condomínio do Edifício Novo Centro Multiempresarial** — a commercial office building at **SRTVS Quadra 701, Bloco O, Brasília-DF**. The look is **corporate, sober and editorial**: a deep green-slate full-bleed hero with a parallax photo of the building façade, an oversized uppercase headline that reveals word-by-word from behind a clipping mask, then a stack of light/dark rounded sections: a building-infrastructure carousel with giant ghost words, a numbered "Condomínio" documents list, an "Conheça o edifício" block with two photo cards, a dark **Avisos** band, a 3-up service cards grid (Classificados / Downloads / Atendimento), and a dark footer. It opens with a **dark intro loader** (logo mark + wordmark + a filling progress bar) that slides up to reveal the hero, at which point the hero text and cards animate in. Smooth scrolling is driven by **Lenis**. Motion is spring-based but **restrained** (corporate, not sporty): clip-mask slide-ups, fade-and-rise, small hover nudges, parallax tied to scroll progress, and two carousels.

The colours come from the building itself: the **green of the façade panels** and the **logo** (mint, black, red, grey bars). Red appears **only** as the "urgente" marker on avisos.

The whole layout is **rem-based and adaptively scaled**: the root `font-size` is recomputed from the viewport width (scales down below 1920px via `vw` media queries, scales up above 1920px via JS). Treat almost every dimension as `rem`.

## Page shell & libraries

- **Lenis** via importmap:
  ```html
  <script type="importmap">
  { "imports": { "lenis": "https://cdn.jsdelivr.net/npm/lenis@1.1.18/+esm" } }
  </script>
  ```
  Load it with a **dynamic `import('lenis')` inside try/catch** so a CDN failure never breaks the page (fall back to native scroll). Init `new Lenis({ smoothWheel: true })` + rAF loop. Scroll lock = `lenis.stop()` + `html { position:relative; overflow:hidden; height:100% }`; unlock = `lenis.start()` + remove those props. Use a **lock counter** so loader/menu/modal/lightbox can overlap safely. On first load `history.scrollRestoration='manual'; scrollTo(0,0)`.
- **Font:** Google **Onest**, weights **400, 500, 600** (`https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600&display=swap`). `body { font-family:"Onest", system-ui, sans-serif }`. Headlines use 500; small numbers/labels may use 600.
- **CSS reset:** border-box; zero margins; `img { display:block; max-width:100%; height:auto }`; `body { min-height:100vh; background:#fff; color:var(--foreground) }`; buttons `cursor:pointer`; `:focus-visible { outline:2px solid var(--brand-light); outline-offset:2px }`. Add `<script>document.documentElement.classList.add('js')</script>` in `<head>` and scope all "hidden before reveal" states under `.js` so content is visible if JS fails.
- **Page frame:** `<main>` has padding `0.5rem` (<640px) / `0.75rem` (≥640px), `width:100%; overflow-x:clip`. This inset gives the hero and dark sections their rounded-card framing.
- **Adaptive rem grid (bake in exactly):**
  ```css
  html { font-size:16px }
  @media (max-width:1920px){ html{ font-size:0.833333vw } }
  @media (max-width:1440px){ html{ font-size:1.111111vw } }
  @media (max-width:1024px){ html{ font-size:1.5625vw } }
  @media (max-width:640px){  html{ font-size:4.444444vw } }
  ```
  ```js
  const FONT_BASE = 16, BASE_W = 1920, COEF = 0.6666;
  const reduction = ((BASE_W - innerWidth) / BASE_W) * 100 * COEF;
  const size = FONT_BASE - (FONT_BASE * reduction) / 100;
  if (size > FONT_BASE) html.style.fontSize = size + "px"; else html.style.removeProperty("font-size");
  ```
  Run on load + resize.

### Token → value map
Spacing: `1`=.25rem, `1.5`=.375rem, `2`=.5rem, `3`=.75rem, `4`=1rem, `5`=1.25rem, `6`=1.5rem, `7`=1.75rem, `8`=2rem, `10`=2.5rem, `11`=2.75rem, `12`=3rem, `14`=3.5rem, `16`=4rem, `20`=5rem, `24`=6rem. Text: `xs`=.75rem, `sm`=.875rem, `base`=1rem, `lg`=1.125rem, `xl`=1.25rem, `2xl`=1.5rem, `3xl`=1.875rem, `4xl`=2.25rem, `5xl`=3rem, `6xl`=3.75rem, `7xl`=4.5rem. `rounded-xl`=.75rem. Breakpoints: sm 640, md 768, lg 1024, xl 1280.

### Palette (`:root`)
```css
--background:#ffffff;  --foreground:#0b1210;
--brand:#2f7a64;       /* façade green — primary */
--brand-deep:#0f2a25;  /* deep green-slate — hero / avisos / footer base */
--brand-light:#7cc8b3; /* logo mint — accents on dark, focus ring */
--accent-dark:#245f4e; /* caption tint on photo cards */
--alert:#b8241c;       /* logo red — ONLY "urgente" avisos */
--surface:#f3f5f4;     /* off-white section bg */
--surface-card:#ffffff;
--ink:#0b1210;         /* headings */
--ink-soft:#6b7672;    /* muted body */
--ghost:#d5dcd9;       /* oversized ghost text */
--hairline:#e3e8e6;    /* borders */
--on-brand:#ffffff;
--radius-card:1.5rem; --radius-card-lg:2rem; --radius-pill:62.5rem;
```
`white@N%` means `rgba(255,255,255,N/100)`; `deep@N%` means `rgba(15,42,37,N/100)`. Never put white text on `--brand-light` (contrast).

### Spring helper, easings and reveal primitives
- rAF spring per property, react-spring model: `v += (-tension*(x-target) - friction*v)*dt; x += v*dt` (mass 1, `dt` clamped to 1/30). Settle at `|Δ|<.001 && |v|<.001`.
- Easings: `easeOutExpo` (clip-mask word/line reveals), `easeOutQuart` (body word fade), `easeInOutCubic` (loader fill + curtain).
- **Clip-mask reveal** (words or lines): `overflow:hidden` box with `padding-bottom:.14em` (lines) / `.12em` (ghost words); inner span `translateY(115%) opacity:0 → translateY(0) opacity:1`, staggered. Re-runnable when carousel content changes.
- **Inview:** spring from `from` to `to` once, when first entering the viewport (IntersectionObserver, threshold .15), after optional `delayIn`.
- **Hover spring:** pointer-enter → `to`, leave → `from`. **Disabled at ≤768px or on `(hover:none)`.**
- `prefers-reduced-motion: reduce` → skip parallax and springs (set final states instantly).

### Logo mark (inline SVG symbol, `viewBox="0 0 48 48"`, fill none)
Simplified Multiempresarial symbol: five vertical bars over three interlocking rings.
- **Mono** (`stroke="currentColor"`): `<path d="M14 6v22M19 2v26M24 6v22M29 2v26M34 6v22" stroke-width="2.4" opacity=".45"/>` + `<ellipse cx="17" cy="32" rx="8" ry="7" stroke-width="3.2"/>` + `<ellipse cx="25" cy="27" rx="8" ry="6.5" stroke-width="3.2"/>` + `<ellipse cx="30" cy="35" rx="10" ry="7.5" stroke-width="3.2"/>`
- **Colour** (for dark backgrounds): same geometry; bars `#b3bcb9`, rings `#b8241c`, `#e9eeec`, `#7cc8b3`.

### Icons (`viewBox 0 0 24 24`, fill none, stroke currentColor, `stroke-width:1.8`, round caps/joins)
Arrow `M5 12h14M13 6l6 6-6 6` · Arrow up-right `M7 17 17 7M8 7h9v9` · X `M6 6l12 12M18 6L6 18` · Check `M5 13l4 4L19 7` · Pin `M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z` + `circle(12,9.5,2.5)` · Phone `M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2` · Mail `rect(3,5,18,14,rx2)` + `M3 7l9 6 9-6` · File `M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8zM14 3v5h5M8 13h8M8 17h6` · Bell `M6 16V11a6 6 0 1 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0` · Key `circle(8,15,4)` + `M11 12l9-9M17 6l3 3` · User `circle(12,8,4)` + `M4 21a8 8 0 0 1 16 0`.

---

## Data layer — Supabase (project `SiteMultiempresarial`, already provisioned)

```js
const SUPABASE_URL = 'https://wekdopgrtqrizmznbirf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_Q04s3B217vNsJtmtrGiHmA_oRwLU67Z'; // chave pública
const sb = (path, opts = {}) => fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
  ...opts, headers: { apikey: SUPABASE_KEY, ...(opts.body ? { 'Content-Type':'application/json' } : {}), ...(opts.headers || {}) }
});
```
Use plain `fetch` against PostgREST (no supabase-js). RLS already allows anon **read** of published rows and anon **insert** into `contatos` only.

| Table | Used by | Query |
|---|---|---|
| `avisos (data, categoria, titulo, texto, urgente, link)` | Avisos band | `avisos?select=data,categoria,titulo,texto,urgente,link&order=data.desc&limit=4` |
| `documentos (secao, titulo, descricao, href, ordem)` | Condomínio list (`secao='condominio'`) and Downloads card (`secao='downloads'`) | `documentos?select=secao,titulo,descricao,href&order=ordem` |
| `galeria_albuns (titulo, descricao, ano, tags, capa, ordem)` + `galeria_fotos (url, legenda, ordem)` | photo lightbox for the Estrutura carousel and the Edifício cards (match by album `titulo`) | `galeria_albuns?select=titulo,descricao,ano,capa,ordem,galeria_fotos(url,legenda,ordem)&order=ordem` |
| `contatos` (insert only) | contact modal | `POST contatos` with `Prefer: return=minimal` |

Rules: render the fallback content below immediately; fetch after the loader finishes; re-render lists when data arrives (new nodes get the same Inview reveal). All DB text via `textContent`; accept only `http(s):`, `/`, `#` or `assets/` hrefs.

## Assets (local, in the repo)

| Path | Use |
|---|---|
| `assets/hero/fachada.jpg` (800×515, colour photo of the façade, sky at top) | hero parallax plate · Estrutura slide 1 · Edifício card 1 · "Bloco O" card thumbnail · Edifício intro chip |
| `assets/logo-multiempresarial.png` (565×428, transparent) | favicon + footer brand tile |

Any place that needs a photo that does not exist yet uses a **brand tile** instead: `background: linear-gradient(160deg, #2f7a64, #0f2a25)` with the **colour logo mark** centred at `4.5rem` and a subtle `repeating-linear-gradient(90deg, rgba(255,255,255,.05) 0 2px, transparent 2px 14px)` "façade panel" stripe overlay. When a matching Supabase album has a `capa`, use that image instead.

---

## Layout & sections (in order)

Inside `<main>`: **Hero → Estrutura → Condomínio → Edifício → Avisos → Serviços → Footer**, plus body-level **Contact modal**, **menu overlay**, **lightbox** and **toast**.

### 1) Site header (inside the hero, transparent)
`<header>` flex row, `padding:1.5rem 1.5rem 0` / `2rem 2.5rem 0` (≥640px), `text-xs`, white.
- **Left nav** (hidden below lg), `flex-1`, gap `2rem`, white@90% → 100% on hover, smooth-scroll: **Estrutura** (`#estrutura`), **Condomínio** (`#condominio`), **Avisos** (`#avisos`).
- **Center brand** (`flex-1`, centred on ≥lg): mono logo mark (`1.5rem`, colour `--brand-light`) + **Multiempresarial**, `text-base`, 500, uppercase, `letter-spacing:.14em`, gap `.5rem`. Click → scroll to top.
- **Right** (`flex-1`, justify-end, gap `1rem`/`1.25rem`):
  - **"Área do condômino"** text link (hidden below xl, uppercase, tracking .08em, underline on hover). Placeholder: shows the toast "A Área do condômino estará disponível em breve."
  - **"Fale Conosco"** text button (hidden below sm, uppercase, tracking .08em, underline on hover) → opens Contact modal.
  - **Burger**: `2.5rem` round, `background:white@15%`, backdrop-blur, hover white@25%; two stacked 1px × 1rem white bars, 5px gap → opens menu overlay. `aria-label="Abrir menu"`.

### 2) Hero
`<section id="inicio">` `--brand-deep` bg, white text, `position:relative; isolation:isolate; overflow:hidden; border-radius:2rem`. Height `calc(100svh - 1rem)` / `calc(100svh - 1.5rem)` (≥640px), `min-height:36rem`. Flex column.
- **Parallax plate** (`absolute inset-0; z-index:-10`): inner layer `left/right:0; top:-16%; height:132%` with `fachada.jpg` (`object-fit:cover; object-position:center 40%`, eager, `fetchpriority=high`, alt "Fachada do Edifício Novo Centro Multiempresarial"). Parallax `translateY(0%) → 12%` across the section scroll progress. Overlay: `linear-gradient(to bottom, rgba(15,42,37,.72), rgba(15,42,37,.40), rgba(15,42,37,.82))`. (The photo is low-resolution; the dark overlay hides that — keep it.)
- **Giant title** (`padding:1rem 1.5rem 0` / sides `2.5rem`): `<h1>` **"Novo Centro"** — `font-size:11vw`, 500, uppercase, `line-height:.85`, `letter-spacing:-.025em`, `white-space:nowrap`. Word clip-mask reveal, **stagger 140ms, 1100ms easeOutExpo**, gated on loader `ready`.
- Below the title (same padding, `margin-top:1rem`): a small Eyebrow (light) **"Condomínio do Edifício Novo Centro Multiempresarial"** — fade in, delay 250ms after ready.
- **Bottom row** (`margin-top:auto; padding:0 1.5rem 2rem` / `0 2.5rem 2.5rem`): column on mobile, row space-between items-end on ≥sm, gap `1.5rem`.
  - **Tagline** `<p>` stacked lines **"Seu negócio"** / **"no centro de Brasília"** — `font-size:2.4rem`, 500, uppercase, `line-height:.95`, tight, white@85%. Stacked-lines reveal baseDelay 350 / stagger 110 / 900ms easeOutExpo, gated. Under it (fade, delay 600ms): a row `[Pin icon brand-light] SRTVS Quadra 701, Bloco O · Brasília-DF` (`text-xs`, uppercase, tracking .08em, white@70%).
  - **Right cluster** (flex, items-end, gap `1rem`):
    - **Acesso rápido slider** (hidden below md, `width:16rem`, column, gap `.75rem`): glass card (flex row gap `.75rem`, `rounded-card`, border white@15%, bg white@10%, padding `.75rem`, shadow deep@20%, backdrop-blur). Left: a `3.5rem` square `rounded-xl` **icon tile** (`background:white@12%`, icon `1.5rem` in `--brand-light`). Right: label (`.7rem`, 500, uppercase, tracking .08em), title (`.7rem`, uppercase, opacity 80%), underlined CTA `"{cta} →"` (`.65rem`) that scrolls to the target section. Slides:
      1. Bell — **"Avisos"** · **"Comunicados da administração"** · cta **"Ver avisos"** → `#avisos`
      2. Key — **"Classificados"** · **"Salas para venda e locação"** · cta **"Ver anúncios"** → `#servicos`
      3. File — **"Downloads"** · **"Convenção e regimento"** · cta **"Ver documentos"** → `#condominio`
      Autoplay 3800ms (paused on hover/focus), wrap-around, gated on ready, cross-fade `{opacity:0,y:16,scale:.96}` → `{opacity:1,y:0,scale:1}` `{tension:210,friction:24}`. Light carousel dots below. Inview rise-in delayIn 650, `{200,26}`.
    - **Endereço card** (Inview rise-in delayIn 780, `{200,26}`): `<article>` width 100% max `20rem` / `15rem` (≥sm), same glass style, flex row gap `.75rem`. Left column space-between: big value **"Bloco O"** (`text-3xl`, 500, line-none); a row of four overlapping `1.25rem` circles (`-0.5rem` overlap, 1px border deep@40%) in the **logo colours** `#b8241c`, `#0b1210`, `#7cc8b3`, `#b3bcb9`; caption **"SRTVS · Quadra 701"** (`.65rem`, opacity 80%). Right: `4rem`-wide `aspect-[3/4]` `rounded-xl` crop of `fachada.jpg` (`object-position:30% center`).

### 3) Estrutura (`#estrutura`) — infrastructure carousel
White section, `position:relative; isolation:isolate; overflow:hidden; padding:4rem 1.5rem` / `5rem 2.5rem`. 3 slides; changing slide re-fires the ghost-word reveals and cross-fades the photo.
- **Top row** (z-20, column → row space-between on ≥sm):
  - **Badge circle** `7rem` / `8rem`, `--surface`: **"Bloco O"** (`text-2xl`, 500) over **"SRTVS Quadra 701"** (`.6rem`, `--ink-soft`, max-width 8em). Inview `{opacity:0,scale:.9}` `{220,22}`.
  - **Badge card** (max-width `28rem`, gap `1rem`/`1.25rem`, `rounded-card`, `--surface`, padding `1.25rem`/`1.5rem`): chip **"#01"** (`rounded-xl`, white bg, `.5rem 1rem`, `text-xl`, 500) + title **"Localização privilegiada"** (`text-lg`, 500) + body **"Situado no centro de Brasília, com variedade de escritórios comerciais para atendê-lo em tudo que precisar."** (`text-xs`, `--ink-soft`, relaxed). Inview `{opacity:0,y:24}` delayIn 120 `{200,26}`.
- **Ghost heading** `<h2>` (pointer-events none, z-0, max-width `88rem`, margin-top `3rem`, centred): `font-size:8.2vw`, 500, uppercase, `line-height:1.02`, tight. Two rows of two words (`justify-between`); **word 3 is `--ink`**, the others `--ghost`. Clip-mask reveal 700ms easeOutExpo, re-fires on slide change. X-parallax: top-left `-3%→3%`, top-right `3%→-3%`, bottom-left `-2%→4%`, bottom-right `4%→-3%`.
  - Slide 1: `["Espaço","Pronto","Para","Crescer"]`
  - Slide 2: `["Reúna","Equipes","Receba","Clientes"]`
  - Slide 3: `["Tudo","Perto","Sem","Sair"]`
- **Centre card** (z-10; on ≥sm absolutely centred; width `13rem` / `16rem`): `<figure>` rotated **4deg** (more sober than 6), `aspect-[3/4]`, `rounded-card`, `--brand` bg, overflow hidden; photo or brand tile; glass caption (`inset-x-3 bottom-3`, `rounded-xl`, deep@45%, blur, `.5rem .75rem`): name (`text-sm`, 500) + subtitle (`.65rem`, opacity 80%). Inview `{opacity:0,y:60,scale:.92}` `{170,26}`; photo cross-fade `{260,26}`. Clicking the card opens the lightbox for that slide's album.
  - Slide 1: `fachada.jpg` — **"Escritórios comerciais"** / "Salas no centro de Brasília" (album "Fachada")
  - Slide 2: brand tile (or album capa) — **"Centro de Convenções"** / "Eventos, reuniões e convenções" (album "Centro de Convenções")
  - Slide 3: brand tile (or album capa) — **"Praça de Alimentação"** / "Alimentação dentro do edifício" (album "Praça de Alimentação")
- **Controls** (z-20, margin-top `3rem`/`6rem`, space-between): prev arrow button (outline), dots (dark, 3), next arrow button (solid). Wrap-around.

### 4) Condomínio (`#condominio`) — documents list
`--surface` bg, `padding:6rem 1.5rem` / sides `2.5rem`.
- Eyebrow **"Condomínio"**; `<h2>` stacked lines **"Tudo sobre"** / **"o condomínio"** (`text-5xl`, 500, line .95, tight, margin-top `1rem`).
- `<ul>` margin-top `3.5rem`: one row per `documentos` row with `secao='condominio'` (fallback below). Each row = `<a>` (or `<div>` if no href) with top border `1px --hairline` (last also bottom). Inview `{opacity:0,y:26}` delayIn `i×90` `{190,26}`; flex row gap `1.5rem`, `padding:1.75rem 0`, centred: index `01…` (`width:2.5rem`, `text-sm`, 500, `--ink-soft`); name (`text-2xl`→`text-3xl`, 500, tight) + description (`text-sm`, `--ink-soft`); trailing `2.75rem` circle (1px hairline) with arrow, hover `x:0→8, opacity .55→1` `{300,20}`. Rows without `href` show a small `"Em breve"` label (`text-xs`, uppercase, `--ink-soft`) instead of the arrow circle.
- Fallback rows (title — description):
  1. **Atas e Relatórios** — Atas de assembleias e relatórios da gestão.
  2. **Financeiro** — Prestação de contas e informações financeiras.
  3. **Administração** — Síndico, conselho e equipe administrativa.
  4. **Informações** — Horários, normas de uso e orientações gerais.
  5. **PGRS e PGRSS** — Planos de gerenciamento de resíduos sólidos e de saúde.
  6. **Lei Geral de Proteção de Dados** — Como o condomínio trata seus dados pessoais (LGPD).
  7. **Convenção e Regimento** — Convenção do condomínio e regimento interno.

### 5) Edifício (`#edificio`)
White, `border-radius:2rem`, **`margin-top:-2.5rem`** (overlaps the surface above), `padding:4rem 1.5rem 5rem` / sides `2.5rem`. Grid 1 → 2 cols (≥md), items-end, gap `2.5rem`.
- **Intro** (max-width `24rem`): a `4rem` `rounded-card` crop of `fachada.jpg` (Inview `{opacity:0,scale:.85}` `{240,20}`); `<h2>` stacked **"Conheça o"** / **"Edifício"** / **"Multiempresarial"** (`text-5xl`, 500, line .95, stagger 120, margin-top `1.5rem`); body **"Escritórios comerciais, Centro de Convenções, Praça de Alimentação e estacionamento rotativo — tudo no Setor de Rádio e TV Sul, no centro de Brasília."** (`text-sm`, `--ink-soft`, max-width `20rem`, margin-top `1.5rem`; word fade y18 → 0, stagger 28ms, delayIn 250, 700ms easeOutQuart). Then (margin-top `1.5rem`) an outline pill **"Ver galeria"** that opens the lightbox with all album photos.
- **Two cards** (flex, items-end, gap `1.25rem`), each `flex-1`, Inview `{opacity:0,y:48}` delayIn `i×140` `{180,26}`; 2nd card `margin-bottom:2rem`. `aspect-[3/4]`, `rounded-card`, overflow hidden, hover scale `1→1.03` `{300,22}`; glass caption (`inset-x-3 bottom-3`, `rounded-xl`, blur, white, `.75rem 1rem`): name (`text-sm`, 500) + description (`.65rem`, opacity 85%). Click → lightbox for that album.
  - Card 1 (caption `deep@45%`): `fachada.jpg` (`object-position:25% center`) — **"Fachada"** — "O edifício no Setor de Rádio e TV Sul."
  - Card 2 (caption `accent-dark@60%`): brand tile / album capa — **"Estacionamento rotativo"** — "Para condôminos e visitantes."

### 6) Avisos (`#avisos`) — dark band (replaces a stats band)
`--brand-deep` bg, white, `border-radius:2rem`, `margin-top:.75rem`, `padding:5rem 1.5rem` / sides `2.5rem`.
- Header row (column → row space-between items-end on ≥md): Eyebrow light **"Avisos"** + `<h2>` stacked **"Comunicados"** / **"da administração"** (`text-5xl`, 500, margin-top `1rem`); right: `text-sm` white@65% max-width `22rem` **"Fique por dentro das informações importantes do condomínio."**
- `<ul>` grid 1 → 2 (≥md) → 4 (≥lg) cols, `gap-x 2rem`, `gap-y 3rem`, margin-top `4rem`. One cell per aviso (max 4), Inview `{opacity:0,y:30}` delayIn `i×110` `{180,24}`; top border `1px white@20%`, `padding-top:1.25rem`:
  - Big date (`text-6xl` → `text-7xl` ≥sm, 500, tight, tabular-nums): day + short month, e.g. **"03 out"** (month lowercase, from `data`), with a `<time datetime>`.
  - Category row (`text-xs`, uppercase, tracking .14em, white@50%, margin-top `.75rem`) — if `urgente`, prepend a pill `Urgente` (`--alert` bg @20%, text `#ff8a80`, pulsing `.375rem` red dot).
  - Title (`text-lg`, 500, margin-top `.5rem`) + texto (`text-sm`, white@65%, 3-line clamp, margin-top `.5rem`); optional underlined link **"Ler aviso →"**.
- **Empty state** (no avisos — the current reality): a single full-width row, top border white@20%, `padding-top:1.25rem`: `[Bell icon brand-light] ` **"Nenhum aviso no momento."** (`text-2xl`, 500) + `text-sm` white@60% **"Os comunicados da administração aparecerão aqui."**

### 7) Serviços (`#servicos`) — 3 cards (replaces testimonials)
White, `padding:5rem 1.5rem` / `6rem 2.5rem`.
- Eyebrow **"Atendimento"**; `<h2>` stacked **"Serviços para"** / **"quem está aqui"** (`text-5xl`, 500, margin-top `1rem`).
- `<ul>` grid 1 → 3 cols (≥md), gap `1.25rem`, margin-top `3.5rem`. Cards: Inview `{opacity:0,y:40}` delayIn `i×120` `{180,26}`, hover lift `y:0→-8` `{300,22}`; `flex column justify-between; height:100%; rounded-card; --surface; padding:1.75rem`. Top: a `3rem` round icon chip (`--brand` bg, white icon `1.25rem`). Title (`text-2xl`, 500, margin-top `1.25rem`), body (`text-sm`, `--ink-soft`, relaxed, margin-top `.75rem`). Footer (border-top hairline, `padding-top:1rem`, margin-top `1.5rem`) with the action.
  1. Key — **Classificados** — "Salas para venda e locação no edifício. Consulte anúncios ou anuncie a sua sala." — action: pill-link **"Falar sobre classificados →"** → opens Contact modal with assunto **Classificados** preselected.
  2. File — **Downloads** — "Convenção, regimento interno e formulários do condomínio." — action: list of `documentos` with `secao='downloads'` (each a row `[File] title · PDF`); fallback rows **Convenção do Condomínio**, **Regimento Interno**, **Formulário de cadastro**, **Formulário de mudança**, each marked **"Em breve"** (no link).
  3. Phone — **Atendimento** — "Fale com a administração por telefone ou e-mail." — action: `tel:` links **(61) 3322-0522** and **(61) 3225-8540**, `mailto:` **administracao@multiempresarial.com.br**.

### 8) Footer (`#contato`)
`--brand-deep`, white, `border-radius:2rem`, `margin-top:.75rem`, `padding:3.5rem 1.5rem` / `4rem 2.5rem`.
- **CTA band** (border-bottom white@15%, `padding-bottom:3.5rem`, column → row space-between items-end ≥sm): Eyebrow light **"Contato"** + stacked `<p>` **"Precisa falar"** / **"com a administração?"** (`text-6xl`, 500, line .92, tight, margin-top `1rem`); right: light pill **"Fale Conosco"** (Inview `{opacity:0,y:20}` delayIn 150 `{200,24}`) → Contact modal.
- **Columns** (`padding-block:3.5rem`, md `1.4fr 1fr 1fr 1fr`, gap `2.5rem`):
  - Brand: `logo-multiempresarial.png` on a white `rounded-xl` tile (`padding:.75rem; width:8rem`); blurb **"Condomínio do Edifício Novo Centro Multiempresarial. Escritórios comerciais no centro de Brasília."** (`text-sm`, white@65%, margin-top `1rem`); `<address>` (not italic, margin-top `1.5rem`, white@80%, `text-sm`, column gap `.375rem`): **condominio@multiempresarial.com.br**, **administracao@multiempresarial.com.br** (mailto), **(61) 3322-0522** (`tel:+556133220522`), **(61) 3225-8540** (`tel:+556132258540`), and muted (white@55%) **SRTVS Quadra 701, Bloco O — Brasília-DF, CEP 70340-000** linking to Google Maps (`https://maps.google.com/?q=SRTVS+Quadra+701+Bloco+O+Bras%C3%ADlia+DF`, new tab).
  - Link columns (heading `text-xs`, 500, uppercase, tracking .2em, white@50%; list `text-sm`, white@80%, gap `.75rem`, hover white + `translateX(4px)`):
    - **Condomínio:** Atas e Relatórios, Financeiro, Administração, Convenção e Regimento (→ `#condominio`)
    - **Edifício:** Estrutura (`#estrutura`), Galeria (opens lightbox), Avisos (`#avisos`), Classificados (`#servicos`)
    - **Acesso:** Área do condômino (toast), Downloads (`#servicos`), Fale Conosco (modal), Como chegar (Maps link)
- **Bottom bar** (border-top white@15%, `padding-top:2rem`, `text-sm`, white@60%, column → row space-between): **"© {ano atual} Condomínio do Edifício Novo Centro Multiempresarial. Todos os direitos reservados."** · Legal nav: **Política de Privacidade**, **LGPD** (both → `#condominio`).

### Shared UI components
- **Eyebrow:** inline-flex, gap `.5rem`, `text-xs`, 500, uppercase, `letter-spacing:.22em`, leading `.375rem` dot. Dark: text `--ink-soft`, dot `--brand`. Light: text white@70%, dot `--brand-light`.
- **Pill button:** inline-flex, gap `.5rem`, `rounded-pill`, `padding:.875rem 1.75rem`, `text-sm`, 500, uppercase, `letter-spacing:.06em`, trailing arrow (`1rem`) springs `x:0→5` on hover `{320,20}`. Variants: `light` (white bg, `--brand-deep` text; hover `--brand` bg, white text), `solid` (`--ink` bg, white; hover `--brand-deep`), `outline` (1px currentColor, `--ink` text; hover ink bg, white text).
- **Arrow button:** `3rem` / `3.5rem` round, 1px border. `outline` (hairline border, ink arrow; hover border ink) and `solid` (ink bg; hover `--brand-deep`). Arrow `1.25rem`, scales `1→1.15` on hover `{320,18}`; prev = `scaleX(-1)`. `aria-label` "Anterior"/"Próximo".
- **Carousel dots:** gap `.5rem`; each a button (`padding:.375rem`) with a `.375rem`-tall pill: active `width:1.25rem` (`--ink` dark / white light), idle `.375rem` (`--ghost` dark / white@40% light). `aria-current` on active, `aria-label="Slide n"`.
- **Toast:** fixed bottom-centre, `--ink` bg, white, `rounded-xl`, `.75rem 1.25rem`, `text-sm`; fades in/out (3.2s).

### Contact modal (body-level, scroll-locked)
Triggers: header "Fale Conosco", menu pill, footer pill, Classificados card (with assunto preset). `position:fixed; inset:0; z-index:90`; flex items-end (mobile) / centre (≥sm); padding `.75rem` / `1.5rem`; closed = `pointer-events:none`.
- Backdrop `deep@45%` + blur, opacity spring `{240,30}`; click closes.
- Panel (`role=dialog aria-modal aria-labelledby`): `{opacity:0,y:28,scale:.96}` → `{1,0,1}` `{240,26}`; `max-height:92svh; overflow-y:auto; rounded-card-lg; white; padding:1.5rem / 2rem; max-width:34rem; --ink`; shadow `0 30px 80px -20px rgba(15,42,37,.45)`.
  - Header: Eyebrow **"Fale conosco"** + stacked `<h2>` **"Como podemos"** / **"ajudar?"** (`text-4xl` → `text-5xl`, 500, stagger 90 / 800ms, margin-top `.75rem`); close button (`2.5rem`, `--surface`, hover `--hairline`) with X that rotates `0→90deg` on hover `{300,18}`.
  - Form (`margin-top:1.75rem`, column gap `1rem`, `novalidate`) — same fields as the current site:
    - **Nome*** (text, required, placeholder "Seu nome")
    - **Endereço** (text, placeholder "Sala / empresa ou endereço")
    - row (≥sm 2 cols): **E-mail*** (email, required, "voce@empresa.com.br") · **Telefone*** (tel, required, "(61) 90000-0000", mask `(00) 00000-0000`)
    - **Assunto** (select): Administração · Financeiro · Manutenção · Classificados · LGPD / Dados pessoais · Outros
    - **Mensagem*** (textarea 4 rows, required, "Escreva sua mensagem.")
    - **Checkbox*** **"Concordo com o tratamento dos meus dados para retorno do contato, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018)."**
    - hidden honeypot `empresa_site`
    - Labels `text-xs`, 500, uppercase, tracking .18em, `--ink-soft`. Inputs `rounded-xl`, 1px hairline, white, `.75rem 1rem`, `text-sm`, focus border `--brand`. Inline errors in `--alert`.
    - Submit (solid pill, full width on mobile): **"Enviar mensagem"** → **"Enviando…"** (disabled).
  - **Submit inserts into Supabase** `contatos` (`nome, endereco|null, email, telefone, assunto, mensagem, consentimento_lgpd:true`, `Prefer: return=minimal`). Honeypot filled → fake success. Error → keep data, show **"Não foi possível enviar agora. Tente novamente ou ligue (61) 3322-0522."**
  - **Success panel** (`margin-top:2rem`, `rounded-card`, `--surface`, `1.5rem`, centred): `3rem` `--brand` circle with white check; **"Mensagem enviada"** (`text-lg`, 500); **"Obrigado, {primeiro nome} — a administração retornará pelo e-mail ou telefone informado."**; solid pill **"Fechar"**.
- Esc closes; focus trap; focus Nome after 120ms; restore focus to trigger on close; reset form 350ms after closing.

### Menu overlay (from the burger)
Body-level, `position:fixed; inset:0; z-index:70`, column; closed = `pointer-events:none`.
- `--brand-deep` backdrop fade `{260,30}`, click closes.
- Panel `{opacity:0,y:-24}` → `{1,0}` `{220,28}`; padding mirrors page inset + header so the close button lands where the burger was.
  - Top: mono mark (`--brand-light`) + **MULTIEMPRESARIAL** (tracking .14em) · close button (`2.5rem`, white@15%, hover white@25%, rotating X).
  - Centre nav (gap `.5rem`): links springing in `{opacity:0,y:28}` delayIn `120 + i×70` `{200,26}`; `text-5xl` → `text-7xl`, 500, tight, hover `--brand-light`, each prefixed by a small index `01`–`06` (`text-base`, 400, white@35%). Links: **Início**, **Estrutura**, **Condomínio**, **Edifício**, **Avisos**, **Contato**. Click → close + smooth-scroll.
  - Bottom (border-top white@15%, `padding-top:2rem`, column → row): light pill **"Fale Conosco"** (close + open modal) · `text-sm` white@70%: **(61) 3322-0522** · **condominio@multiempresarial.com.br** · live **Brasília HH:MM** clock (`Intl.DateTimeFormat('pt-BR',{timeZone:'America/Sao_Paulo',hour:'2-digit',minute:'2-digit'})`, updates every 30s).
- Esc closes; lock/unlock scroll.

### Lightbox
Body-level, `z-index:95`, `deep@94%` bg; title row (album name + close); centred image (`object-fit:contain`, `rounded-xl`), prev/next arrow buttons (light) when >1 photo, caption `legenda · n / total`. Empty album → **"Fotos em breve."** Esc / backdrop closes, ←/→ navigate, scroll locked, focus trapped.

## The loader / reveal

Fixed curtain `inset:0; z-index:200; --brand-deep; white`, centred column, gap `2rem`:
- Wordmark: **colour logo mark** (`2.25rem`) + **MULTIEMPRESARIAL** (`text-2xl`, 500, uppercase, tracking .14em); below it `text-xs` uppercase tracking .2em white@45% **"Novo Centro · Brasília"**. Springs in `{opacity:0,y:16}` → `{1,0}` `{200,22}`.
- Progress track `10rem × 1px`, white@20%, with a `--brand-light` fill scaling X `0→1` (origin left), delay 120ms, duration 1280ms easeInOutCubic.

Timing: `MIN_VISIBLE_MS = 1400`, `MAX_VISIBLE_MS = 2600`, `EXIT_MS = 850`. Lock scroll on mount; after `load` (or immediately if complete) wait `MIN_VISIBLE_MS` (force after `MAX_VISIBLE_MS`); then `ready = true` (plays hero title, eyebrow, tagline, slider, endereço card), unlock scroll, slide curtain `0% → -105%` over 850ms easeInOutCubic, remove after. Then fetch Supabase data. Reduced motion: min 200ms, instant exit.

## `<head>`
```html
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Multiempresarial — Condomínio do Edifício Novo Centro Multiempresarial</title>
<meta name="description" content="Condomínio do Edifício Novo Centro Multiempresarial — escritórios comerciais em localização privilegiada no centro de Brasília. SRTVS Quadra 701, Bloco O." />
<meta name="theme-color" content="#0f2a25" />
<link rel="icon" href="assets/logo-multiempresarial.png" />
```

## Fixed parameters (summary)

- **Colours:** `#ffffff #0b1210 #2f7a64 #0f2a25 #7cc8b3 #245f4e #b8241c #f3f5f4 #6b7672 #d5dcd9 #e3e8e6`. Logo dots `#b8241c #0b1210 #7cc8b3 #b3bcb9`.
- **Radii:** card 1.5rem, card-lg 2rem, pill 62.5rem, xl .75rem. **Page inset** .5rem / .75rem; dark-band gaps .75rem; Edifício `margin-top:-2.5rem`.
- **Type:** Onest 400/500/600. Hero title `11vw` "Novo Centro"; tagline `2.4rem`; ghost heading `8.2vw` (words ≤ 9 letters so rows never overflow at 360px).
- **Loader:** 1400 / 2600 / 850ms; fill 120ms delay, 1280ms.
- **Hero:** title stagger 140 / 1100ms; tagline 350 / 110 / 900; slider delayIn 650, autoplay 3800, cross-fade `{210,24}`; endereço card delayIn 780; parallax 0→12%.
- **Estrutura:** ghost reveal 700ms; card rotate 4deg `{170,26}`; photo fade `{260,26}`.
- **Condomínio:** rows `i×90` `{190,26}`; arrow hover `x 0→8` `{300,20}`.
- **Edifício:** icon `{240,20}`; title stagger 120; body words 28ms / 250ms / 700ms; cards `i×140` `{180,26}`; hover scale 1.03 `{300,22}`.
- **Avisos:** cells `i×110` `{180,24}`.
- **Serviços:** cards `i×120` `{180,26}`; lift −8 `{300,22}`.
- **Modal / menu / lightbox:** as specified. **Hover disabled ≤768px.**
- **Quality bar:** no horizontal scroll at 360–2560px; Lighthouse a11y ≥ 95; every icon-only control has a pt-BR `aria-label`; images lazy except the hero plate.
