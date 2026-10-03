# Recreate this site as a single HTML file: Multiempresarial — Condomínio do Edifício Novo Centro Multiempresarial

You are an expert creative front-end developer. Produce a **single self-contained `index.html`** for the new website of the **Condomínio do Edifício Novo Centro Multiempresarial** (Brasília-DF), following the spec below **exactly** — layout, sections, visuals, motion, and interaction. Pure HTML/CSS/JS in one file: no build step, no framework, no bundler. Use ES modules with a CDN importmap for the one library used (Lenis smooth-scroll). All CSS lives in one `<style>` block in `<head>`; all JS in one `<script type="module">` block before `</body>`. Spring / text-reveal animations are done with **plain JS** (a tiny rAF spring helper and/or CSS transitions).

**All visible copy is Brazilian Portuguese (`<html lang="pt-BR">`)** and must be used verbatim as written here. Do not invent facts (numbers, dates, names, prices) that are not in this spec.

Editable content (avisos, galeria, documentos) is **loaded from Supabase** at runtime (see "Data layer — Supabase" below). The JS arrays `AVISOS`, `GALERIA`, `DOCUMENTOS` shown in each section are the **offline fallback** (used if the fetch fails or returns nothing) and define the exact shape each renderer expects.

## Data layer — Supabase (project `SiteMultiempresarial`)

Add to the importmap: `"@supabase/supabase-js": "https://esm.sh/@supabase/supabase-js@2"`.

```js
import { createClient } from '@supabase/supabase-js';
const SUPABASE_URL = 'https://wekdopgrtqrizmznbirf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_Q04s3B217vNsJtmtrGiHmA_oRwLU67Z'; // chave pública (publishable), segura no front
const db = createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { persistSession: false } });
```

The schema already exists (migrations in `supabase/migrations/`). RLS: visitors can **read** only rows with `publicado = true`, and can only **insert** into `contatos` (never read it).

| Table | Columns used by the site | Query |
|---|---|---|
| `avisos` | `data, categoria, titulo, texto, urgente, link` | `db.from('avisos').select('data,categoria,titulo,texto,urgente,link').order('data',{ascending:false}).limit(6)` |
| `documentos` | `secao ('condominio'\|'downloads'), titulo, descricao, href, ordem` | `db.from('documentos').select('secao,titulo,descricao,href').order('ordem')` → split by `secao` into the Condomínio list and the Downloads list |
| `galeria_albuns` + `galeria_fotos` | `titulo, descricao, ano, tags, capa, ordem` + `fotos(url, legenda, ordem)` | `db.from('galeria_albuns').select('titulo,descricao,ano,tags,capa,galeria_fotos(url,legenda,ordem)').order('ordem')` |
| `contatos` (insert only) | `nome, endereco, email, telefone, assunto, mensagem, consentimento_lgpd` | `db.from('contatos').insert({...})` — **no `.select()`** after insert (anon cannot read the row back) |

Rules:
- Render the fallback arrays immediately (so reveals/layout never wait on the network), then fetch all three in parallel after `ready` and re-render the lists when data arrives. Re-attach reveal observers to new nodes (already-revealed sections render new nodes in their final state, no animation).
- Photo URLs may be relative (`assets/...`) or Supabase Storage public URLs (bucket `galeria`) — use them as-is.
- `assunto` must be one of: `Administração`, `Financeiro`, `Manutenção`, `Classificados`, `LGPD / Dados pessoais`, `Outros` (DB check constraint).
- Escape all text coming from the DB (`textContent`, never `innerHTML`). Only allow `http(s):`, relative or `#` hrefs.

## What it is

A single-page, light-palette institutional site for a commercial office building in the centre of Brasília. It is built on a rem-based adaptive grid (root font-size scales with the viewport), uses Google **Onest** as the only typeface, and reads as near-white surfaces (`#ffffff` page, `#eef1f0` cool-grey fills) punctuated by deep green-black ink cards (`#0c1412`) and a single accent taken from the building's façade and logo: **façade green `#2f7a64`** (mint `#7cc8b3` highlight on dark). The logo's red `#b8241c` is used **only** as the "urgent" marker on avisos.

It opens with a **full-screen dark intro loader** that counts `000 → 100` and slides up; only then do the above-the-fold reveals play. The hero is a **full-bleed photo of the building with a "liquid" cursor-reveal**: the façade is shown desaturated, and moving the pointer paints a soft brush trail of the full-colour photo over it. On top: a giant `MULTIEMPRESARIAL` watermark, a line-by-line headline, a quick-access carousel card and an "Estrutura" list. Below: an About statement (Sobre o Condomínio), a four-pill "Trabalhe / no centro / → / de tudo" band, an **Avisos** card row, a **Galeria** of black cards, a **Condomínio** documents list with hover-fill rows, a **Classificados + Downloads** split, a black **Localização & Contato** panel with a map, and a black footer with CTA, link columns and watermark. A header (Menu button + live Brasília clock + "Área do condômino") overlays the hero; Menu opens a full-screen dark overlay; every "Entrar em contato / Fale com a administração" CTA opens a **contact modal** (stubbed submit). Smooth scrolling is driven by **Lenis**.

Sections in DOM order: **PageLoader** → **Header** (fixed overlay) → `main`{ **Hero** → **Sobre** → **Band** → **Avisos** → **Galeria** → **Condomínio** → **Classificados/Downloads** → **Contato** } → **Footer** → **NavMenu** (overlay) → **ContactModal** (overlay).

## Page shell & libraries

### `<head>`

```html
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Multiempresarial — Condomínio do Edifício Novo Centro Multiempresarial</title>
<meta name="description" content="Condomínio do Edifício Novo Centro Multiempresarial — escritórios comerciais em localização privilegiada no centro de Brasília. SRTVS Quadra 701, Bloco O." />
<meta name="theme-color" content="#0c1412" />
<link rel="icon" href="assets/logo-multiempresarial.png" />
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### Importmap + module entry (before `</body>`)

```html
<script type="importmap">
{ "imports": { "lenis": "https://unpkg.com/lenis@1.3.23/dist/lenis.mjs" } }
</script>
<script type="module"> /* all JS below */ </script>
```

```js
import Lenis from 'lenis';
window.scrollTo(0, 0);
const lenis = new Lenis({ smoothWheel: true });
function raf(t){ lenis.raf(t); requestAnimationFrame(raf); }
requestAnimationFrame(raf);
```

**Scroll lock model.** `stopScroll()` = `lenis.stop()` + `html { position:relative; overflow:hidden; height:100% }`; `startScroll()` = `lenis.start()` + remove those three inline styles. Used by loader, nav overlay and contact modal.

**`scrollTo(id)` helper.** After `50ms`, `window.scrollTo({ top: el.getBoundingClientRect().top + pageYOffset, behavior:'smooth' })`. Used by logo, nav links and in-page buttons.

### Global CSS reset / base

```css
*{ box-sizing:border-box; margin:0; padding:0 }
html{ font-size:16px; -webkit-font-smoothing:antialiased }
body{ background:#ffffff; color:#111816; font-family:'Onest',sans-serif; overflow-x:hidden }
a{ color:inherit; text-decoration:none }
button{ font:inherit; color:inherit; background:none; border:none; cursor:pointer }
ul{ list-style:none }
img{ display:block; max-width:100% }
.sr-only{ position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0 }
:focus-visible{ outline:2px solid #2f7a64; outline-offset:2px }
@media (prefers-reduced-motion: reduce){ *{ animation:none !important; transition:none !important } }
```

### The rem-based adaptive grid (CRITICAL — bake exactly)

```css
@media (max-width:1920px){ html{ font-size:0.833333vw } }
@media (max-width:1440px){ html{ font-size:1.111111vw } }
@media (max-width:1024px){ html{ font-size:1.5625vw } }
@media (max-width:640px){  html{ font-size:4.444444vw } }
```

Scale-up above 1920px (runtime JS):

```js
function applyAdaptiveGrid(){
  const FONT_BASE = 16, baseWidth = 1920, coef = 0.6666;
  const w = window.innerWidth;
  const widthReduction = ((baseWidth - w) / baseWidth) * 100;
  const size = FONT_BASE - (FONT_BASE * (widthReduction * coef)) / 100;
  if (size > FONT_BASE) document.documentElement.style.fontSize = size + 'px';
  else document.documentElement.style.removeProperty('font-size');
}
applyAdaptiveGrid(); addEventListener('resize', applyAdaptiveGrid);
```

All sizes below are in rem (Tailwind scale: `text-sm`=.875rem, `text-base`=1rem, `text-lg`=1.125rem, `text-xl`=1.25rem, `text-2xl`=1.5rem, `text-3xl`=1.875rem, `text-4xl`=2.25rem, `text-5xl`=3rem, `text-6xl`=3.75rem, `text-7xl`=4.5rem). Keep them in rem. Breakpoints: sm `640px`, md `768px`, lg `1024px`.

### Spring helper & text reveals

- rAF spring stepper, mass 1: `accel = tension*(target-x) - friction*v`, `dt≈1/60`, settle at `|Δ|<0.001 && |v|<0.001`. CSS equivalents allowed: `{210,26}` ≈ `cubic-bezier(.22,1,.36,1)` .7s; `{200,24}`/`{180,26}` ≈ `cubic-bezier(.16,1,.3,1)` .8s; hovers `{320,18}` ≈ `cubic-bezier(.2,.8,.2,1)` .35s.
- Hovers are disabled on touch (`@media (hover:hover)` / `matchMedia('(hover: hover)')`).
- **Line reveal** (overflow clip, inner span `translateY(100%→0)` + `opacity 0→1`, 900ms `cubic-bezier(.215,.61,.355,1)`, optional `lineStagger`).
- **Word reveal** (each word `translateY(24px→0)` + `opacity 0→1`, stagger 35ms, 700ms `cubic-bezier(.165,.84,.44,1)`).
- Generic **reveal** (`.reveal` with `data-delay`, `data-y`, `data-scale`): plays once via IntersectionObserver (`threshold:.15`). Hero reveals are additionally gated on the loader `ready` flag.

## Palette & tokens (bake these in)

```
--background:#ffffff   --foreground:#111816
--ink:#0c1412          (green-black cards / pills / overlays)
--muted:#7f8a87        --subtle:#b3bcb9
--line:#e2e6e5         (hairline borders)
--surface:#eef1f0      --surface-2:#dfe4e3
--accent:#2f7a64       (façade green)  --accent-from:#7cc8b3 (logo mint)  --accent-to:#245f4e
--alert:#b8241c        (logo red — ONLY for "urgente" avisos)
--hero-to:#c7cfcd      (hero bg fallback)
```
Radii: pill `9999px`, card `2rem`, card-sm `1.25rem`, control `.875rem`. Shell `.shell{ max-width:88rem; margin-inline:auto }`, default `padding-inline:1.25rem` (sm `2rem`).

**Watermark** (`MULTIEMPRESARIAL` is 16 letters, so it is sized in vw, not rem): `font-size:clamp(2.25rem, 8.6vw, 20rem); letter-spacing:-.03em; white-space:nowrap; font-weight:700; line-height:1`.

### Brand assets (local files in the repo)

| Path | Use |
|---|---|
| `assets/logo-multiempresarial.png` | full logo (transparent PNG, 565×428). Used in the footer brand column and as favicon. |
| `assets/hero/fachada.jpg` | the building photo (800×600). Used in the hero and in the Galeria "Fachada" card. **The photo has a red date stamp in the bottom-right corner** → always render it with `object-position:center 35%` and in the hero scale the cover by `1.08` so the stamp is cropped out. |

### Inline SVG icons (sized `1em`, `currentColor`)

- **LogoMark** (simplified, monochrome version of the Multiempresarial symbol — 5 vertical bars over three interlocking rings), `viewBox="0 0 48 48"`, `fill="none" stroke="currentColor"`:
  `<path d="M14 6v22M19 2v26M24 6v22M29 2v26M34 6v22" stroke-width="2.4" opacity=".45"/>`
  `<ellipse cx="17" cy="32" rx="8" ry="7" stroke-width="3.2"/>`
  `<ellipse cx="25" cy="27" rx="8" ry="6.5" stroke-width="3.2"/>`
  `<ellipse cx="30" cy="35" rx="10" ry="7.5" stroke-width="3.2"/>`
- **LogoMarkColor** — same geometry, bars `stroke:#b3bcb9`, rings stroked `#b8241c`, `#111816`, `#7cc8b3` (in that order). Used in the loader and the hero card tile.
- **ArrowRight** `M5 12h14M13 6l6 6-6 6` · **ArrowUpRight** `M7 17 17 7M8 7h9v9` (stroke 2, round)
- **MapPin** stroke 1.6: `M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z` + `<circle cx=12 cy=9.5 r=2.5/>`
- **Phone** stroke 1.6: `M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2`
- **Mail** stroke 1.6: `<rect x=3 y=5 width=18 height=14 rx=2/>` + `M3 7l9 6 9-6`
- **FileText** stroke 1.6: `M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8z M14 3v5h5 M8 13h8M8 17h6`
- **Bell** stroke 1.6: `M6 16V11a6 6 0 1 1 12 0v5l2 2H4z M10 20a2 2 0 0 0 4 0`
- **User** stroke 1.6: `<circle cx=12 cy=8 r=4/>` + `M4 21a8 8 0 0 1 16 0`
- **X** `M4 4l16 16M20 4 4 20` · **Grid/menu** `M4 6h16M4 12h16M4 18h16` · **CircleDot** `<circle r=9/>` + filled `<circle r=3.2/>` · **ChevronDown** `M6 9l6 6 6-6`

---

## PageLoader

`position:fixed; inset:0; z-index:120; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:2rem; background:#0c1412; color:#fff; border-radius:0 0 2rem 2rem`. `stopScroll()` on mount.

- Center (`gap:1.25rem; text-align:center`): row `font-weight:600; font-size:1.5rem` (sm 1.875rem) `[LogoMarkColor 2.25rem] Multiempresarial`; below, `font-size:.75rem; text-transform:uppercase; letter-spacing:.08em; color:rgba(255,255,255,.45)` **"Condomínio do Edifício Novo Centro Multiempresarial"**; below, `max-width:28ch; font-size:.875rem; color:rgba(255,255,255,.6)` **"No centro de Brasília, perto de tudo."**
- Progress `width:min(22rem,72vw); gap:.75rem`: 1px track `rgba(255,255,255,.15)` with fill `#7cc8b3`, `transition:width .1s ease-out`. Row below (`.75rem; 500; uppercase; .05em; rgba(255,255,255,.45)`): **"Carregando"** / tabular-nums counter `rgba(255,255,255,.8)` zero-padded to 3 digits.
- Count `0→100` over `FILL_MS = 1300`, easeInOutCubic. At 100: panel `translateY(0→-100%)` (~.7s `cubic-bezier(.22,1,.36,1)`), content `opacity 1→0, translateY(0→-12px)`. On finish: `ready = true`, `startScroll()`, remove loader.

---

## 1) Header (overlay, entrance after `ready`, delay 150ms, `opacity 0→1, translateY(-14px→0)`)

`position:absolute; inset-inline:0; top:0; z-index:50`. `.shell` flex row, `justify-content:space-between; align-items:center; gap:1.5rem; padding:1.25rem` (sm `1.5rem 2rem`).

- **Brand button** (→ `scrollTo('inicio')`), hover `scale 1.04`: `display:flex; align-items:center; gap:.5rem; font-size:1.125rem; font-weight:600; letter-spacing:-.01em` → `[LogoMark 1.5rem color:#2f7a64] Multiempresarial`.
- **Primary nav** (hidden below lg): `ul gap:2rem; font-size:.875rem; font-weight:500`, hover lift `translateY(-2px)`, `opacity .8→1`. Items: **Início** (`aria-current=page`, → `#inicio`), **Avisos** (→ `#avisos`), **Condomínio** + ChevronDown `.75rem opacity .6` (dropdown, see below), **Galeria** (→ `#galeria`), **Classificados** (→ `#classificados`), **Downloads** (→ `#downloads`), **Contato** (opens modal).
  - **Condomínio dropdown:** opens on hover (desktop) and on click/Enter (`aria-expanded`). Panel `position:absolute; top:calc(100% + .75rem); left:-1rem; min-width:16rem; border-radius:1.25rem; background:rgba(255,255,255,.92); backdrop-filter:blur(12px); box-shadow:0 20px 40px -20px rgba(12,20,18,.35); outline:1px solid #e2e6e5; padding:.5rem`; enters `opacity 0→1, translateY(6px→0)` .25s. Items (`display:block; padding:.6rem .875rem; border-radius:.875rem; font-size:.875rem; hover background:#eef1f0`) = the 7 `DOCUMENTOS` titles; each → `scrollTo('documentos')` (and optionally highlights that row). Close on outside click / Escape.
- **Right group** (`display:flex; gap:.5rem`):
  - **Clock chip** (hidden below md): `border:1px solid rgba(226,230,229,.8); background:rgba(255,255,255,.45); backdrop-filter:blur(4px); border-radius:.875rem; padding:.5rem .75rem; gap:.75rem; font-size:.75rem`. Label **"Brasília"** `rgba(17,24,22,.45)`, then live **time** (`min-width:2.75rem; tabular-nums; 500; #111816`), `•` (`rgba(17,24,22,.3)`), live **date** (500).
    - Clock JS, every 1s, **always in `America/Sao_Paulo`** via `Intl.DateTimeFormat('pt-BR', { timeZone:'America/Sao_Paulo', ... })`. Time = `HH:MM` 24h (e.g. `14:05`). Date = `D de mês de AAAA` lowercase month (e.g. `3 de outubro de 2026`). Fallback before first tick: `--:--` / empty.
  - **Área do condômino** link (`href="#login"`, placeholder for the future login): same chip styling as Menu, inner `[User .875rem] Área do condômino`, label hidden below lg (icon only).
  - **Menu button** (→ NavMenu): chip styling, `hover background:rgba(255,255,255,.75)`, inner `padding:.5rem 1rem; .75rem; 500; uppercase; .05em` → `[Grid .875rem] Menu` ("Menu" hidden below sm).

---

## 2) Hero (`#inicio`) — façade with liquid colour reveal

`section#inicio`: `position:relative; isolation:isolate; overflow:hidden; border-radius:0 0 2rem 2rem; background:#c7cfcd`.

**A) LiquidReveal background** (`position:absolute; inset:0; z-index:0`). Both layers use the **same photo** `assets/hero/fachada.jpg`:
- Base `<img>` (LCP, `fetchpriority="high"`): `object-fit:cover; object-position:center 35%; transform:scale(1.08); filter:grayscale(1) contrast(1.05) brightness(1.12)` — the desaturated façade.
- `<canvas aria-hidden>` on top (`pointer-events:none`) painting the **full-colour** photo along the cursor trail. When building the offscreen cover canvas, apply the same cover math **including the 1.08 scale and the 35% vertical focal point** so colour and grey align pixel-perfectly.
- Params & algorithm unchanged: `brushRadius = 143` CSS px, `decay = 0.016`/frame, `dpr = min(devicePixelRatio,2)`, ResizeObserver re-measure, `pointermove` on window, ignore points > radius outside (reset `last`), interpolate `step = max(radius*.3,1)`, `n = min(ceil(dist/step),60)`.
- Tick: queued points → `idle=0`, else `idle++`, bail at `idle>120`. `fade = drawing ? decay : min(decay + idle*0.004, .5)`; `destination-out` fill `rgba(0,0,0,fade)`; stamp each point; hard `clearRect` when idle hits 120.
- `stamp(x,y)`: brush canvas — radial gradient stops `0→rgba(255,255,255,1)`, `.55→rgba(255,255,255,.82)`, `1→rgba(255,255,255,0)`; then `source-in` draw the matching region of the colour cover canvas; then `source-over` onto main canvas at `(x-c, y-c)`.
- `prefers-reduced-motion: reduce` or no hover (touch) → no canvas; show the **colour** photo statically instead of the grey one.

**B) Legibility vignette** `z-index:1; pointer-events:none; background:linear-gradient(to bottom, rgba(255,255,255,.55), rgba(255,255,255,.1) 45%, rgba(255,255,255,.55))`. (Stronger than usual because the photo has a bright sky.)

**C) Watermark** `position:absolute; inset-inline:0; bottom:6rem; z-index:1; text-align:center; pointer-events:none; user-select:none; color:rgba(255,255,255,.45)` + watermark sizing → **MULTIEMPRESARIAL**. Reveal after `ready`: `opacity 0→1, translateY(20px→0)`, delay 300ms.

**D) Content** `.shell` `position:relative; z-index:20; display:flex; flex-direction:column; gap:2rem; padding:7rem 1.25rem 5rem` (lg: `display:grid; min-height:100lvh; grid-template-columns:repeat(12,1fr); gap:2.5rem; padding:9rem 2rem 7rem`).

- **Left** (lg `span 7`, `gap:1.75rem`):
  - Eyebrow (delay 200): dot + **"SRTVS · Quadra 701 · Bloco O"**.
  - **H1** line reveal (delay 250, `lineStagger 120`): `max-width:18ch; font-size:2.25rem; font-weight:600; line-height:.98; letter-spacing:-.02em` (sm 3rem, md 3.75rem). Lines: **"Seu negócio"** / **"no coração"** / **"de Brasília."** — the last line in `color:#2f7a64`.
  - Info row (delay 650): `display:flex; align-items:center; gap:.75rem` → `[MapPin 1.125rem color:#2f7a64]` + `font-size:.875rem; 500; rgba(17,24,22,.7)` **"Escritórios comerciais em localização privilegiada"**.
  - CTAs (delay 750, `gap:.75rem; flex-wrap:wrap`): **"Fale com a administração"** (PillButton `dark`, arrow → opens modal) and **"Ver avisos"** (`outline` → `scrollTo('avisos')`).
- **Right** (lg `span 5`, `align-items:flex-start`, lg `flex-end`, `gap:2rem`):
  - **Acesso rápido card** (carousel; reveal `translateY(16px) scale(.96→1)`, delay 400): `width:100%; max-width:24rem` (lg `19rem`); `border-radius:1.25rem; background:rgba(255,255,255,.72); padding:.5rem; box-shadow:0 1px 2px rgba(0,0,0,.05), 0 0 0 1px rgba(226,230,229,.7); backdrop-filter:blur(12px)`. Row `display:flex; gap:.5rem`:
    - Left tile `6rem` square, `border-radius:.875rem; background:#0c1412; display:grid; place-items:center; font-size:2.25rem` with **LogoMarkColor**.
    - Right panel `flex:1; border-radius:.875rem; background:rgba(238,241,240,.75); padding:.75rem; display:flex; flex-direction:column; justify-content:space-between`. Slot (`min-height:3.25rem`): caption `.65rem; 500; uppercase; .05em; rgba(17,24,22,.45)` over title `max-width:9rem; .875rem; 500; line-height:1.35`. Items:
      1. `{ caption:"Avisos", title:"Comunicados da administração.", target:"avisos" }`
      2. `{ caption:"Classificados", title:"Salas e anúncios do edifício.", target:"classificados" }`
      3. `{ caption:"Downloads", title:"Convenção, regimento e formulários.", target:"downloads" }`
    - Bottom row: 3 dash dots (active `width:1rem; rgba(17,24,22,.7)`, inactive `.375rem; rgba(17,24,22,.2)`, `height:.25rem`, `transition:all .3s`) + prev/next buttons (`1.75rem` round white, ring `#e2e6e5`). **Clicking the text panel scrolls to the current item's `target`**; prev/next cycle `(i+step+n)%n`; also auto-advance every 5s, paused on hover/focus. Swap: outgoing `translateY(±14px)` fade, incoming from `∓14px`.
  - **Estrutura list** (reveal `translateY(14px)`, delay 550): `max-width:24rem` (lg `19rem`). Label `.75rem; 500; rgba(17,24,22,.45)` (lg right-aligned) **"Estrutura do edifício"**. Grid `repeat(2,1fr); column-gap:1rem; row-gap:.75rem`; each item hover `translateY(-2px)`, `opacity .75→1`: `[CircleDot .875rem color:rgba(47,122,100,.7)]` + `.75rem; rgba(17,24,22,.75)` name. Items: **Escritórios comerciais, Centro de Convenções, Praça de Alimentação, Estacionamento rotativo**.

**E) Status bar** (opacity reveal, delay 900): `.shell` flex `space-between; gap:.75rem; border-top:1px solid rgba(17,24,22,.1); padding:1.25rem; .75rem; 500; uppercase; .025em; rgba(17,24,22,.6)`. Left **"Brasília · DF"**; center (hidden below sm) **"CEP 70340-000"**; right **"Role para explorar ↓"**.

---

## 3) Sobre (`#sobre`)

`section#sobre` white. `.shell` grid `1fr` (lg `1fr 1fr`), `align-items:center; gap:3rem; padding-block:5rem` (lg 7rem).

- **Left — photo block** (reveal `translateY(24px) scale(.98→1)`): `position:relative; aspect-ratio:4/3; overflow:hidden; border-radius:2rem; background:#dfe4e3` containing `fachada.jpg` (`object-fit:cover; object-position:center 35%; transform:scale(1.08)`; on hover of the block the image eases to `scale(1.12)` over .8s). Overlaid bottom-left chip: `position:absolute; left:1rem; bottom:1rem; display:inline-flex; gap:.5rem; align-items:center; border-radius:9999px; background:rgba(255,255,255,.85); backdrop-filter:blur(8px); padding:.5rem 1rem; .75rem; 500` → `[MapPin] SRTVS Quadra 701, Bloco O`.
- **Right — statement** (`gap:2.5rem`):
  - Eyebrow **"Sobre o Condomínio"**.
  - **H2** word reveal: `1.5rem; 500; line-height:1.35; -.01em` (sm 1.875rem): **"Situado em uma localização privilegiada, no centro de Brasília, "** + in `color:#7f8a87`: **"com variedade de escritórios comerciais para atendê-lo em tudo que precisar."**
  - Footer row (reveal, delay 200): `flex-wrap; align-items:flex-end; justify-content:space-between; gap:1.5rem; border-top:1px solid #e2e6e5; padding-top:1.5rem`. Left: label `.875rem; rgba(17,24,22,.45)` **"Fale conosco"** over 3 round chips (`2.25rem`, icon hover `scale 1.18`): **Telefone** (`background:#2f7a64; color:#fff`, Phone icon, `href="tel:+556133220522"`, `aria-label="Ligar para (61) 3322-0522"`), **E-mail** (`#eef1f0`, Mail, `mailto:condominio@multiempresarial.com.br`), **Mapa** (`#eef1f0`, MapPin, `href="https://maps.google.com/?q=SRTVS+Quadra+701+Bloco+O+Brasília+DF"`, `target=_blank rel=noopener`). Right: PillButton **"Entrar em contato"** (`outline`, arrow → opens modal).

---

## 4) Band ("Trabalhe no centro → de tudo")

`ul.shell` `flex-direction:column; gap:.75rem; padding-block:2.5rem` (sm row, `gap:1rem`). Four `li flex:1`, reveal `translateY(28px)` delay `i*120`, tile hover `scale 1.03`: `display:grid; place-items:center; height:6rem; border-radius:9999px; font-size:1.875rem; font-weight:500` (sm `height:10rem; 2.25rem`).
1. **"Trabalhe"** — `background:#eef1f0; color:#111816`
2. **"no centro"** — `background:linear-gradient(to bottom right,#7cc8b3,#245f4e); color:#fff`
3. ArrowRight (`2.25rem`, sm 3rem) — `background:#0c1412; color:#fff`
4. **"de tudo"** — `background:rgba(238,241,240,.6); color:rgba(17,24,22,.35)`

---

## 5) Avisos (`#avisos`)

`section#avisos` white, `.shell padding-block:2.5rem 5rem`.

- Header row `display:flex; flex-wrap:wrap; align-items:flex-end; justify-content:space-between; gap:1.5rem; margin-bottom:2.5rem`: left = Eyebrow **"Avisos"** + H2 line reveal (`margin-top:1rem; 2.25rem; 600; -.02em`, sm 3rem) **"Comunicados da administração"**; right = `.875rem; rgba(17,24,22,.55); max-width:22rem` **"Fique por dentro das informações importantes do condomínio."**
- Grid `1fr` (md 2, lg 3 cols), `gap:1.5rem`, rendered from `AVISOS` (show the 6 most recent by `data`). Card = reveal `li` (`translateY(32px)`, delay `i*90`) → hover `translateY(-6px)`: `display:flex; flex-direction:column; gap:1rem; min-height:15rem; border-radius:1.25rem; background:#eef1f0; padding:1.5rem; outline:1px solid transparent; hover outline-color:#dfe4e3`.
  - Top row `.75rem; 500; uppercase; .04em; rgba(17,24,22,.5)`: left `[Bell] <categoria>`; right the date formatted `D mmm AAAA` pt-BR (e.g. `3 out 2026`).
  - If `urgente:true`: a pill `background:rgba(184,36,28,.1); color:#b8241c; .7rem; 600; uppercase; padding:.25rem .625rem` **"Urgente"** with a pulsing `.375rem` red dot.
  - `h3 1.25rem; 600; line-height:1.25` = titulo; `p .875rem; rgba(17,24,22,.65); line-height:1.55` = texto (clamp 4 lines). If `link`, a bottom `AnimatedLink` **"Ler aviso →"**.
- Empty state (array empty): a single `#eef1f0` card **"Nenhum aviso no momento."**
- `AVISOS` format — ship it with the placeholders below and a comment `// TODO: substituir pelos avisos reais da administração`:

```js
const AVISOS = [
  { data:'2026-10-01', categoria:'Administração', titulo:'Título do aviso', texto:'Texto do aviso publicado pela administração do condomínio.', urgente:false, link:null },
  { data:'2026-09-24', categoria:'Manutenção',    titulo:'Título do aviso', texto:'Texto do aviso publicado pela administração do condomínio.', urgente:true,  link:null },
  { data:'2026-09-15', categoria:'Segurança',     titulo:'Título do aviso', texto:'Texto do aviso publicado pela administração do condomínio.', urgente:false, link:null },
];
```

---

## 6) Galeria (`#galeria`)

`section#galeria` white, `.shell padding-block:2.5rem 5rem` (lg pb 7rem).

- Eyebrow centered with border pill (`border:1px solid #e2e6e5; border-radius:9999px; padding:.375rem 1rem`) **"Galeria de Fotos"**; H2 centered line reveal (`2.25rem; 600`, sm 3rem) **"Conheça o edifício"**.
- Grid `1fr` (md 2 cols), `gap:1.5rem`, from `GALERIA`. Card = reveal `li` (`translateY(48px)`, delay `i*90`) → hover `translateY(-8px) scale(1.012)` `article`: `position:relative; min-height:22rem; overflow:hidden; border-radius:2rem; background:#0c1412; padding:1.5rem; color:#fff` (sm `min-height:26rem; padding:2rem`).
  - If `capa` is set: `img` absolutely filling the card, `object-fit:cover; opacity:.55`, with a `linear-gradient(to top, #0c1412 10%, transparent 70%)` overlay; on card hover image `scale 1.05` + `opacity .7`. If `capa` is `null`: centered **LogoMark** watermark `4.5rem; rgba(255,255,255,.9)`.
  - Top meta row (`.75rem; uppercase; .025em; rgba(255,255,255,.5)`): left `Galeria — <ano or "Multiempresarial">`; right badge `2.75rem` round `rgba(255,255,255,.1)` with ArrowUpRight, hover (by card) `rotate 45deg scale 1.08`.
  - Bottom block (`position:absolute; inset-inline:1.5rem; bottom:1.5rem`, sm 2rem): `h3 1.5rem; 500` (sm 1.875rem) = titulo; `p margin-top:.5rem; max-width:28rem; .875rem; rgba(255,255,255,.6)` = descricao; tag chips (`border:1px solid rgba(255,255,255,.25); border-radius:9999px; padding:.5rem 1rem; .875rem`).
  - Clicking a card opens a simple **lightbox** (`position:fixed; inset:0; z-index:118; background:rgba(12,20,18,.92)`) listing that album's `fotos` (array of image paths; if empty, show "Fotos em breve."). Esc / X / backdrop closes; ←/→ navigate; `stopScroll()` while open.

```js
const GALERIA = [
  { titulo:'Fachada',                    ano:null,   descricao:'O Edifício Novo Centro Multiempresarial, no Setor de Rádio e TV Sul.', tags:['Edifício','SRTVS'],          capa:'assets/hero/fachada.jpg', fotos:['assets/hero/fachada.jpg'] },
  { titulo:'Centro de Convenções',       ano:null,   descricao:'Espaço para eventos, reuniões e convenções.',                             tags:['Eventos','Convenções'],       capa:null, fotos:[] },
  { titulo:'Eventos',                    ano:null,   descricao:'Registros dos eventos realizados no condomínio.',                          tags:['Eventos'],                     capa:null, fotos:[] },
  { titulo:'Estacionamento Rotativo',    ano:null,   descricao:'Estacionamento rotativo para condôminos e visitantes.',                   tags:['Estacionamento'],              capa:null, fotos:[] },
  { titulo:'Praça de Alimentação',       ano:null,   descricao:'Opções de alimentação dentro do edifício.',                               tags:['Alimentação'],                 capa:null, fotos:[] },
  { titulo:'Simulação de Evacuação',     ano:2023,   descricao:'Simulado de evacuação realizado com a brigada do edifício.',              tags:['Segurança','Brigada'],         capa:null, fotos:[] },
];
// TODO: adicionar as fotos de cada álbum em assets/galeria/<album>/
```

---

## 7) Condomínio (`#documentos`)

`section#documentos` white, `.shell padding-block:5rem` (lg 7rem).

- Eyebrow **"Condomínio"**; H2 line reveal (`margin:1.25rem 0 3rem; max-width:18ch; 2.25rem; 600; -.02em`, sm `3rem; mb 3.5rem`) **"Tudo sobre o condomínio"**.
- Rows from `DOCUMENTOS`: reveal `li` (`translateY(24px)`, delay `i*80`), `border-top:1px solid #e2e6e5` (not first) → link row with hover fill: `background rgba(238,241,240,0)→1; padding-inline 1.5rem/1.5rem → 2rem/1.25rem`; base `display:flex; align-items:center; gap:1rem; border-radius:1.25rem; padding-block:1.5rem` (sm `gap:1.5rem; 2rem`). Cells: index `01…07` (`width:1.75rem`, sm 2.5rem, `.875rem; 500; rgba(17,24,22,.4)`); `h3 flex:1; 1.5rem; 500` (sm 1.875rem, md 2.25rem); description `p` (hidden below lg, `max-width:20rem; .875rem; rgba(17,24,22,.55)`); badge `2.5rem` (sm 3rem) round `#0c1412`/white with ArrowUpRight, hover (by row) `translateX(5px)`.

```js
const DOCUMENTOS = [
  { titulo:'Atas e Relatórios',              descricao:'Atas de assembleias e relatórios da gestão.',                 href:'#' },
  { titulo:'Financeiro',                     descricao:'Prestação de contas e informações financeiras.',              href:'#' },
  { titulo:'Administração',                  descricao:'Síndico, conselho e equipe administrativa.',                  href:'#' },
  { titulo:'Informações',                    descricao:'Horários, normas de uso e orientações gerais.',               href:'#' },
  { titulo:'PGRS e PGRSS',                   descricao:'Planos de gerenciamento de resíduos sólidos e de saúde.',     href:'#' },
  { titulo:'Lei Geral de Proteção de Dados', descricao:'Como o condomínio trata seus dados pessoais (LGPD).',         href:'#' },
  { titulo:'Convenção e Regimento',          descricao:'Convenção do condomínio e regimento interno.',                href:'#' },
];
// TODO: apontar cada href para a página ou PDF correspondente
```

---

## 8) Classificados & Downloads

`section` white, `.shell padding-bottom:5rem` (lg 7rem). Grid `1fr` (lg `1fr 1fr`), `gap:1.5rem`. Both cards reveal (`translateY(40px) scale(.99→1)`, second delay 120ms).

- **Classificados** (`id="classificados"`): `border-radius:2rem; background:#0c1412; color:#fff; padding:2.5rem 1.5rem` (sm 3rem 2.5rem); `min-height:22rem; display:flex; flex-direction:column; justify-content:space-between`. Top: Eyebrow (light tone) **"Classificados"**; H2 (`margin-top:1rem; 1.875rem; 500`, md 2.25rem) **"Salas para venda e locação no edifício."**; `p margin-top:1rem; .875rem; rgba(255,255,255,.55); max-width:30rem` **"Consulte os anúncios de condôminos e anuncie a sua sala."** Bottom: PillButton **"Ver classificados"** (`light`, arrow `up-right`, `href="#"` TODO).
- **Downloads** (`id="downloads"`): `border-radius:2rem; background:#eef1f0; padding:2.5rem 1.5rem` (sm 3rem 2.5rem). Eyebrow **"Downloads"**; H2 (`1.875rem; 500`) **"Documentos e formulários."**; list (`margin-top:2rem`) of rows `display:flex; align-items:center; gap:1rem; padding-block:1rem; border-top:1px solid #dfe4e3`, hover label `translateX(4px)`: `[FileText 1.25rem color:#2f7a64]` + `flex:1; .9375rem; 500` name + `.75rem; uppercase; rgba(17,24,22,.45)` **"PDF"**. Items (placeholders, `href="#"` + TODO): **Convenção do Condomínio**, **Regimento Interno**, **Formulário de cadastro**, **Formulário de mudança**.

---

## 9) Contato (`#contato`) — black panel with map

`section#contato` white, `.shell padding-bottom:5rem` (lg 7rem). Panel (reveal `translateY(40px) scale(.99→1)`): `border-radius:2rem; background:#0c1412; color:#fff; padding:3rem 1.5rem` (sm `4rem 2rem`, md `padding-inline:4rem`), grid `1fr` (lg `1fr 1fr`), `gap:3rem`.

- **Left:** Eyebrow light **"Contato"**; H2 line reveal (`margin-top:1rem; max-width:18ch; 1.875rem; 500`, md 2.25rem) **"Estamos no centro de Brasília."** Then a list (`margin-top:2.5rem; display:grid; gap:1.5rem`), each item a reveal (`translateY(20px)`, delay `i*90`) = `[icon 1.25rem color:#7cc8b3]` + caption (`.75rem; uppercase; .04em; rgba(255,255,255,.45)`) over value (`1.125rem; 500`, links with AnimatedLink hover):
  - **Endereço** — "SRTVS Quadra 701, Bloco O" / "Brasília-DF · CEP 70340-000"
  - **Telefones** — `(61) 3322-0522` (`tel:+556133220522`) · `(61) 3225-8540` (`tel:+556132258540`)
  - **E-mails** — `condominio@multiempresarial.com.br` · `administracao@multiempresarial.com.br` (mailto, `word-break:break-all` on mobile)
  - Then PillButton **"Enviar mensagem"** (`light`, arrow → opens modal).
- **Right:** map frame `min-height:20rem; border-radius:1.25rem; overflow:hidden; background:#1a2421` with a **lazy** Google Maps embed: `<iframe loading="lazy" referrerpolicy="no-referrer-when-downgrade" title="Mapa — SRTVS Quadra 701, Bloco O" src="https://maps.google.com/maps?q=SRTVS%20Quadra%20701%20Bloco%20O%20Bras%C3%ADlia&output=embed" style="width:100%;height:100%;border:0;filter:grayscale(.6) contrast(1.05)">`. Below the frame an AnimatedLink **"Abrir no Google Maps ↗"** (`target=_blank`).

---

## 10) Footer

`footer` `position:relative; overflow:hidden; border-radius:2rem 2rem 0 0; background:#0c1412; color:#fff`. `.shell` `position:relative; z-index:10; padding:5rem 1.25rem 2.5rem` (sm px 2rem; lg pt 6rem).

- **CTA row** (`flex-direction:column; gap:2rem; border-bottom:1px solid rgba(255,255,255,.1); padding-bottom:4rem`; lg row, `align-items:flex-end; justify-content:space-between`): H2 line reveal (`lineStagger 100`, `max-width:18ch; 2.25rem; 600; -.02em`, sm 3rem, md 3.75rem) **"Precisa falar com a administração?"**; PillButton **"Entrar em contato"** (`light`, arrow `up-right` → modal).
- **Columns** (`grid 1fr; gap:3rem; padding-block:4rem`; md 2 cols; lg 4 cols):
  - Brand: `assets/logo-multiempresarial.png` on a white rounded tile (`background:#fff; border-radius:1.25rem; padding:1rem; width:9rem`) + `margin-top:1.25rem; max-width:20rem; .875rem; rgba(255,255,255,.55)` **"Condomínio do Edifício Novo Centro Multiempresarial. SRTVS Quadra 701, Bloco O — Brasília-DF."**
  - **Condomínio:** Atas e Relatórios, Financeiro, Administração, Convenção e Regimento (→ `#documentos`).
  - **Acesso rápido:** Avisos (`#avisos`), Galeria de Fotos (`#galeria`), Classificados (`#classificados`), Downloads (`#downloads`), Área do condômino (`#login`).
  - **Contato:** (61) 3322-0522, (61) 3225-8540, condominio@multiempresarial.com.br, administracao@multiempresarial.com.br (tel:/mailto:).
  - Titles `.75rem; uppercase; .025em; rgba(255,255,255,.4)`; links `.875rem`, AnimatedLink (`translateX 0→4px, opacity .65→1`).
- **Legal bar** (`flex column → sm row; justify-content:space-between; gap:1rem; border-top:1px solid rgba(255,255,255,.1); padding-top:2rem; .75rem; rgba(255,255,255,.45)`): **"© 2026 Condomínio do Edifício Novo Centro Multiempresarial. Todos os direitos reservados."** (year via `new Date().getFullYear()`); right **Política de Privacidade** (`#privacidade`), **LGPD** (`#documentos`).
- **Watermark** `position:absolute; inset-inline:0; bottom:-1rem; z-index:0; text-align:center; pointer-events:none; color:rgba(255,255,255,.05)` + watermark sizing → **MULTIEMPRESARIAL**.

---

## 11) NavMenu (full-screen overlay)

`position:fixed; inset:0; z-index:115; display:flex; flex-direction:column; background:#0c1412; color:#fff`; fade `opacity 0↔1` (~.4s). Open → `stopScroll()`, Escape closes; close → `startScroll()`.

- Top bar: `[LogoMark 1.5rem color:#7cc8b3] Multiempresarial` (`1.125rem; 600`); **Fechar** button (`border:1px solid rgba(255,255,255,.15); border-radius:.875rem; padding:.5rem 1rem; .75rem; 500; uppercase; .05em; rgba(255,255,255,.7)`; hover border `.4`, `#fff`) → `[X] Fechar`.
- Nav (`flex:1; justify-content:center`): items stagger in (`transition:all .5s ease-out; delay i*45+80ms`, from `translateY(1rem) opacity 0`). Each: `display:flex; gap:1rem; padding-block:.5rem; 2.25rem; 600; -.02em` (sm 3.75rem), index `01…` (`1rem; 400; rgba(255,255,255,.3)`, hover `#7cc8b3`), label `rgba(255,255,255,.7)` hover `#fff`. Items: **Início, Avisos, Condomínio, Galeria, Classificados, Downloads, Contato** (Contato → `scrollTo('contato')`; all close the menu first).
- Bottom bar (`border-top:1px solid rgba(255,255,255,.1); .75rem; uppercase; .025em; rgba(255,255,255,.45)`; sm row): left **"Brasília — <hora>"**; middle **"(61) 3322-0522"** (tel link); right **"Fale com a administração →"** (→ closes menu + opens modal).

---

## 12) ContactModal

Backdrop `position:fixed; inset:0; z-index:110; display:flex; align-items:flex-end` (sm center) `; justify-content:center; padding:1rem; background:rgba(12,20,18,.35); backdrop-filter:blur(16px)`, `role=dialog aria-modal=true aria-labelledby`. Backdrop click / Escape closes; focus trapped inside; focus returns to the trigger on close. Panel `opacity 0↔1` + `translateY(28px→0→18px)`. Panel: `width:100%; max-width:34rem; max-height:calc(100dvh - 2rem); overflow:auto; border-radius:2rem; background:#fff; padding:1.5rem` (sm 2rem), `box-shadow:0 25px 50px -12px rgba(0,0,0,.25), 0 0 0 1px #e2e6e5`. Close button top-right `2.25rem` round `#eef1f0`.

**Form state:**
- Heading: `[.375rem dot #2f7a64] Entrar em contato` (`.875rem; 500; rgba(17,24,22,.6)`), `h2 1.5rem; 600` (sm 1.875rem) **"Como podemos ajudar?"**
- Fields (caption `.75rem; 500; uppercase; .025em; rgba(17,24,22,.5)`; controls `width:100%; border:1px solid #e2e6e5; background:rgba(238,241,240,.5); border-radius:.875rem; padding:.75rem 1rem; .875rem`, focus `border:rgba(17,24,22,.3); background:#fff`). Same fields as the current site's form:
  - **Nome*** (text, required, `autocomplete=name`, placeholder "Seu nome")
  - **Endereço** (text, placeholder "Sala / empresa ou endereço")
  - two-column row (sm+): **E-mail*** (email, required, placeholder "voce@empresa.com.br") · **Telefone*** (tel, required, placeholder "(61) 90000-0000", light mask `(00) 00000-0000`)
  - **Assunto** (select): Administração · Financeiro · Manutenção · Classificados · LGPD / Dados pessoais · Outros
  - **Mensagem*** (textarea, 4 rows, required, `resize:none`, placeholder "Escreva sua mensagem.")
  - **LGPD checkbox*** (required): **"Concordo com o tratamento dos meus dados para retorno do contato, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018)."**
- Bottom row: `.75rem; rgba(17,24,22,.45)` **"Seus dados estão seguros e serão usados apenas para responder ao seu contato."** + PillButton **"Enviar mensagem"** (`dark`, arrow `up-right`, `type=submit`; label "Enviando…" while submitting).
- **Submit goes to Supabase:** validate (native validity + inline error text in `#b8241c` under invalid fields), show "Enviando…", then `await db.from('contatos').insert({ nome, endereco: endereco || null, email, telefone, assunto, mensagem, consentimento_lgpd: true })`. On success → success state. On error → keep the form filled and show under the button, in `#b8241c`: **"Não foi possível enviar agora. Tente novamente ou ligue (61) 3322-0522."** Add a hidden honeypot field (`name="empresa_site"`, `tabindex=-1`, `autocomplete=off`); if it is filled, fake success without inserting.

**Success state** (centered): `3.5rem` round `#0c1412` badge with LogoMark `#7cc8b3`; `h2 1.5rem; 600` **"Mensagem enviada"**; `max-width:34ch; .875rem; rgba(17,24,22,.6)` **"Obrigado pelo contato. A administração retornará pelo e-mail ou telefone informado."**; PillButton **"Fechar"** (`dark`). Reset form 300ms after closing.

---

## Shared components

- **PillButton** — `inline-flex; align-items:center; gap:.75rem; border-radius:9999px; .875rem; 500`; hover `scale 1.04`. Variants: `dark` (`#0c1412`/`#fff`), `light` (`#eef1f0`/`#111816`), `outline` (`border:1px solid #e2e6e5`; on the hero use `border-color:rgba(17,24,22,.2); background:rgba(255,255,255,.5); backdrop-filter:blur(6px)`). With arrow: padding `.375rem .375rem .375rem 1.5rem` + `2.25rem` round badge (dark → `#fff`/`#0c1412`; others → `#0c1412`/`#fff`) whose icon nudges `translate(3px,0)` (right) or `translate(2px,-2px)` (up-right) on hover. Without arrow: `.875rem 1.75rem`.
- **Eyebrow** — `inline-flex; gap:.5rem; .875rem; 500`, `.375rem` dot. Dark tone text `rgba(17,24,22,.7)` dot `#2f7a64`; light tone text `rgba(255,255,255,.7)` dot `#7cc8b3`.
- **AnimatedLink** — inline-flex, hover `translateX(0→4px)`, `opacity .65→1`.
- **Skip link** first in body: **"Pular para o conteúdo"** → `#main`.

## Quality bar

- Lighthouse a11y ≥ 95: all icon-only buttons have pt-BR `aria-label`s, contrast AA (white text on `#2f7a64` passes; never put white text on `#7cc8b3`).
- No horizontal scroll at 360px; watermarks never cause overflow (`overflow:hidden` on their sections).
- Images: `loading="lazy"` everywhere except the hero; explicit `width`/`height` attributes.
- Nothing from the old Wix site (Correio Braziliense news feed, "Created by…" credit) is carried over.
