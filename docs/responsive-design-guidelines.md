# Responsive Design Guidelines

**Target Users:** Students on Chromebooks  
**Last Updated:** 2026-08-11

---

## Table of Contents
- [Overview](#overview)
- [Breakpoints](#breakpoints)
- [Container queries](#container-queries-the-components-own-width-not-the-windows)
- [Two tiers is not two widths](#two-tiers-is-not-two-widths)
- [Four smaller things](#four-smaller-things-the-field-now-takes-as-given)
- [Make the checks automatic](#make-the-checks-automatic)
- [Touch Targets](#touch-targets)
- [Typography](#typography)
- [Spacing & Layout](#spacing--layout)
- [Tables](#tables)
- [Forms](#forms)
- [Images & Media](#images--media)
- [Navigation](#navigation)
- [Testing Requirements](#testing-requirements)
- [Common Patterns](#common-patterns)
- [Quick Reference](#quick-reference)
- [Checklist](#checklist)
- [Additional Resources](#additional-resources)

---

## Overview

> ✅ Use only `base` and `lg:` responsive tiers.
> ✅ Test across the range — 320 to 1920 — **and at 200% text**, not at two widths.
> Two tiers is a statement about layout. It is not permission to check two numbers.

These guidelines ensure a consistent, accessible responsive design across the **Stocks in the Future** application.  
All contributors working on responsive features must follow these standards.

**Core Principles**
- 🎯 **Mobile-first:** design for the smallest screen and scale up.
- 💧 **Fluid first:** adapt with wrapping, `minmax()`, `min-h-*` and `clamp()` before reaching for a
  tier. A breakpoint is for a change of *layout*, not a change of size.
- 💻 **Chromebook-aware:** 1366×768 and 375px get the closest attention, because that is who uses
  this. They are not the reason there are two tiers — see below.
- ✋ **Touch-friendly:** buttons are 40px (`h-10`), which clears WCAG 2.5.8's 24×24 comfortably. 44px
  is the AAA / Apple HIG figure and is reserved for bare tap targets with no other affordance.
- 🎨 **Tailwind, with named component classes:** utilities in markup, and shared patterns as `.tw-*`
  classes in `app/assets/tailwind/`. Not "no custom CSS" — that was never true, and a rule nobody
  follows is worse than no rule. What is banned is a one-off inline style or an arbitrary value that
  has a scale equivalent; `test/design_system/no_arbitrary_values_test.rb` enforces it.
- ♿ **Accessible:** WCAG 2.1 AA, including 1.4.4 and 1.4.10, which are the two this document is
  mostly about.

---

## Breakpoints

Two responsive tiers, and only two:

| Tier | Width | Tailwind prefix | What changes |
|------|-------|-----------------|--------------|
| **Base** | up to 1023px | *(no prefix)* | One column. Navigation is a drawer. Secondary table columns fold into the row. |
| **Large** | 1024px and up | `lg:` | Persistent sidebar, multi-column forms and layouts, full tables. |

`sm:`, `md:`, `xl:` and `2xl:` are not used. Neither is a custom breakpoint.

### Why two, and how that squares with the industry

The field's rule is **content-based breakpoints, not device-based**: add one where *your layout*
breaks, not where a popular phone happens to end. That is the position in Ethan Marcotte's original
responsive work, in Brad Frost's writing, in Google's web.dev guidance, and in Tailwind's own
documentation, and the reason is that a list of device widths goes stale while a layout's own
breaking point does not.

Measured against what major systems ship, two is at the low end and deliberately so:

| System | Breakpoints |
|--------|-------------|
| Tailwind (default) | 5 — `sm` 640, `md` 768, `lg` 1024, `xl` 1280, `2xl` 1536 |
| Bootstrap 5 | 5 — 576, 768, 992, 1200, 1400 |
| Material 3 | 5 window classes — compact, medium, expanded, large, extra-large |
| Primer (GitHub) | 4 — 544, 768, 1012, 1280 |
| Polaris (Shopify) | 4 — 490, 768, 1040, 1440 |
| GOV.UK | 3 — mobile, tablet 641, desktop 769 |
| **This app** | **2 — base, `lg` 1024** |

The justification is not "our users have two devices". It is that **this app's layouts change shape
exactly once**: below 1024px there is no room for a 256px sidebar beside the content, and above it
there is. Nothing else in the product has a second, different breaking point. A third tier would be a
breakpoint with no layout change behind it, and every one of those is a place for two versions of a
component to drift apart.

That the audience is bimodal — school Chromebooks at 1366×768 and phones at 375px — is the reason
those two widths get the closest attention. It is **not** the reason there are two tiers, and the
distinction matters, because the device framing is what produces the mistake in the next section.

### Adapt fluidly before reaching for a breakpoint

When a component needs to respond more finely than "one column or two", the answer is a **fluid
technique**, not a new tier:

- `flex-wrap` with `gap`, so a row becomes two rows when it must
- `grid-template-columns: repeat(auto-fit, minmax(...))` instead of counting columns per tier
- `min-h-*` rather than `h-*` on anything containing text that can rewrap
- `clamp()` for a size that should scale continuously
- a measured value published as a custom property, where one element's size has to drive another's

This is intrinsic web design, and it is why the staging ribbon needs no breakpoint at all: it is
`min-h-8`, it grows when its text wraps, and everything below it follows its **measured** height.
The version it replaced was `h-8` — a fixed number chosen for one width — and it failed at every
width below 1024px as soon as anyone zoomed.

---

## Container queries: the component's own width, not the window's

**This is the rule that keeps two viewport tiers viable.** A viewport breakpoint answers "how wide is
the window"; a component almost always needs "how wide am *I*". Those diverge the moment anything is
placed in a column, a card, a modal or a table cell — and when they diverge, viewport tiers give the
wrong answer with total confidence.

Tailwind v4 ships container queries; no plugin. Mark the container and size against it:

```html
<div class="@container">
  <article class="flex flex-col gap-3 @lg:flex-row @lg:items-center">
    ...
  </article>
</div>
```

Note the units: `@lg:` is **container-relative** (32rem), not the 1024px viewport `lg:`. `@min-[20rem]:`
and `@max-md:` also work.

### When to use which

| | Use |
|---|---|
| The **page** changes shape — sidebar appears, one column becomes two | viewport tier (`lg:`) |
| A **component** could appear at more than one width — in a card, a column, a modal, a table cell, a drawer | container query (`@container` + `@lg:` etc.) |
| A single element needs to grow with its own content | neither — `min-h-*`, `flex-wrap`, `minmax()`, `clamp()` |

### Why this matters here specifically

Every "this component broke somewhere else" bug in this repo is a component sized against the viewport
while living in a narrower box:

- the classroom page put a roster at 765px beside a 256px rail, and the narrow one had less room than
  it needed while reading as subordinate
- a `flex-1` pane needs `min-w-0` or a wide table inside it refuses to shrink
- a four-across stat band is fine on a full-width page and wrong in a column
- a table's row actions were off screen at 375px because the *page* scrolled, carrying the pinned cell
  with it

A viewport breakpoint cannot express any of those, and the usual response — add `md:`, add `xl:` — is
how a two-tier system becomes a five-tier one without anybody deciding to. **Reach for a container
query instead of a new viewport tier.** This is where the field has moved: Polaris, Material and
GitHub all put component adaptation on container queries and keep viewport breakpoints for page
layout.

### Adoption: nothing uses this yet, and that is not an oversight

**No component in this app currently needs a container query, and one was not added to give the rule a
caller.** That was considered and rejected on evidence:

- `reflow_test` walks every main page at 320px and at 200% text and passes, so nothing is being pushed
  around by a viewport tier answering the wrong question.
- The obvious candidate was `components/ui/_stat`, which renders both in a four-across band and inside a
  card. Measured on `classrooms#show` at 1024px it is 151px wide with no overflow and no label wrap; at
  1366px, 236px. It does not misbehave, and `@container` on it would have been a rule pretending to have
  a use.
- Every case that *has* come up this year was fixed by a fluid technique instead - `flex-wrap` on the
  admin header, the discard tabs and the callout, `min-w-0` on a flex item that would not shrink,
  `min-h-*` on the staging band. Those are the first four bullets above, and they kept working.

So the rule stands as the answer to a question that will be asked: **when a component must change its
layout because of its own width, use a container query rather than adding a viewport tier.** The trigger
is a *layout* change - one column becoming two, a row becoming a stack - not a size change, which
`clamp()` covers, and not an overflow, which wrapping covers.

Recorded this plainly because the alternative is worse in both directions. A rule with no caller drifts
as surely as no rule - this repo has the receipts, `tw-input-primary` sat unused for months while nine
forms rendered at 2.54:1. And a caller invented to satisfy a rule is an abstraction nobody asked for,
which is the other half of the same problem.

---

## Two tiers is not two widths

**The layout has two tiers. It must work at every width, continuously, from 320px up.** These are
different claims, and conflating them has already shipped an accessibility failure here.

This is a WCAG obligation, not a preference:

- **1.4.10 Reflow (AA)** — content must work at a 320px-equivalent viewport without two-dimensional
  scrolling. Data tables are the documented exception; nothing else is.
- **1.4.4 Resize text (AA)** — no loss of content or functionality at 200% text. This is the one that
  gets missed, because a layout that is fine at 375px can break entirely at 375px + 200%.

### What went wrong when this was only two widths

The staging ribbon was checked at 375px and 1366px, passed both, and was shipped. At **200% text** it
failed at every width below 1024px: its sentence wraps to four lines on a phone, the rigid `h-8` box
kept its height, and the overflow went *both* ways. Measured at 320px, the text began at **y = -48** —
above the top of the viewport, and it was `position: fixed`, so it could not be scrolled to. Two lines
were unreachable and the rest covered the header.

Nothing in a two-width check can see that. The failure is not at a width; it is at a width *and* a
text size, on a box whose height was a constant.

### Verify across the range

Before submitting anything that changes layout, check:

- [ ] **320, 375, 768, 1024, 1366, 1920** — the two tiers plus the boundaries and the extremes
- [ ] **375px and 1024px at 200% text** — the 1.4.4 case
- [ ] `document.documentElement.scrollWidth === clientWidth` at every width (no sideways scroll)
- [ ] no element rendering above `y = 0` or outside its container
- [ ] a control inside a scroll container is measured against **that container's** box, not the
      viewport's — "present in the DOM" is not "on screen"

Above ~1584px, also check anything the layout renders beside `yield`: a width cap is invisible below
that, because the content box is already narrower than the cap.

`test/system/environment_ribbon_test.rb` and `test/system/spacing_test.rb` assert this class of thing
in pixels rather than in class names, which is the only way it stays true.

---

## Four smaller things the field now takes as given

**Logical properties, not physical ones.** `ms-`/`me-`, `ps-`/`pe-`, `text-start`/`text-end`,
`border-s`/`border-e` rather than `ml-`/`mr-`/`text-left`/`text-right`. Tailwind v4 supports them and
they cost nothing today; retrofitting a whole app's `left`/`right` later is what costs. design.md's
"the last column right-aligns" is `text-end`. This app is English-only and that is not the point — the
point is that the physical version encodes an assumption for no benefit.

**A convention for new and rebuilt markup, not a sweep.** Nothing here uses them yet, and converting
several hundred existing utilities for an app with one language would be churn with no reader on the
other end. The cost of *not* starting is that the pile grows.

**Fluid sizes with `clamp()` where the step is arbitrary.** `text-xl lg:text-3xl` is two guesses and a
jump; `clamp()` is one continuous curve, and it is what Utopia-style scales and most modern systems
ship. Use it for type and space that should scale with the viewport. Keep discrete steps where the
value is a *token* — a button's 40px height is a decision, not a curve.

Also unused today, and for a reason worth knowing: nearly every size in this app **is** a token from
design.md's scale, and a token is exactly the case `clamp()` is wrong for. The place it would earn its
keep is a display figure that wants to grow with the page.

**`dvh` / `svh`, not `vh`.** `100vh` is wrong on a phone the moment the browser chrome collapses;
`dvh` tracks it. `chrome.css` uses `100dvh` for the drawer for exactly this reason.

**Respect `prefers-reduced-motion`.** Anything that moves — the drawer's 300ms transform, a fade —
should collapse to no transition when the user has asked for that. It is a WCAG-adjacent expectation
and a one-line media query. Note the related trap already recorded here: a transition that *never*
fires leaves an auto-hiding element on screen forever, so remove on a timer rather than on
`transitionend`.

---

## Make the checks automatic

A manual checklist rots. This repo has the receipts: the ribbon passed a two-width review and shipped a
1.4.4 failure, and a spacing test once **passed while asserting nothing** because a layout change moved
the selector out from under it.

So the range checks belong in the suite, asserted in pixels:

- `test/system/spacing_test.rb` and `page_rhythm_test.rb` measure boxes, not class names
- `environment_ribbon_test.rb` asserts the 200%-text case and the compiled `z-index`
- `no_arbitrary_values_test.rb` rejects an inline style or an arbitrary value with a scale equivalent

**Still to build**, and the highest-value gap: a test that walks the main pages at **320px** and at
**200% text** and asserts, for every one, that `documentElement.scrollWidth === clientWidth`, that no
element renders above `y = 0`, and that no interactive element sits outside its scroll container's box.
Every failure found by hand in this session would have been caught by it.

---

## Touch Targets

### Minimum Sizes

WCAG 2.5.8 (AA) asks for 24×24. 44×44 is the AAA figure and Apple's HIG recommendation; this app
uses it where a control is *only* a tap target, and its own 40px button height elsewhere.

| Element | Size | Notes |
|----------|------|-------|
| Buttons | 40px (`h-10`) | design.md's height token, and what `.tw-btn-*` uses. Setting these to 44px once made them visibly taller than every other button in the app. |
| Inputs | 44px | Taller than the button on purpose: a field is a target you aim at, not one you skim past. |
| Checkboxes | 24×24px | Make the label clickable, which is what actually enlarges the target. |
| Icon-only controls | 44×44px | Hamburger, close, sidebar nav rows. No visible label, so nothing else makes them findable — and they need their own visually hidden text, because `lucide_icon` is `aria-hidden`. |

**Align the box that paints.** A 44px target centring a 24px icon puts the glyph 10px inside its box,
and the fix is not to pull the box out with a negative margin: that drags whatever paints with it. If
a control has a hover fill, align its box and let the glyph sit inside.

### Spacing

```html
<!-- Minimum 8px spacing between targets -->
<div class="flex gap-2">
  <button class="min-h-[44px] px-4">Action</button>
  <button class="min-h-[44px] px-4">Action</button>
</div>

<!-- Preferred 16px spacing -->
<div class="flex gap-4">
  <button class="min-h-[48px] px-6">Primary</button>
  <button class="min-h-[48px] px-6">Secondary</button>
</div>
```

---

## Typography

| Element | Mobile (`base`) | Chromebook (`lg:`) |
|----------|------------------|--------------------|
| H1 | `text-2xl` (24px) | `lg:text-4xl` (36px) |
| H2 | `text-xl` (20px) | `lg:text-3xl` (30px) |
| Body | `text-base` (16px) | `lg:text-lg` (18px) |
| Small | `text-sm` (14px) | `lg:text-base` (16px) |

**Rules**
1. Never go below 14px (`text-sm`) for body text.
2. Use responsive Tailwind typography classes (`text-xl lg:text-3xl`).
3. Maintain heading hierarchy.

**Example**
```html
<h1 class="text-2xl lg:text-4xl font-bold">Welcome to Your Financial Journey</h1>
<p class="text-base lg:text-lg">This is your launchpad to earn, invest, and grow.</p>
```

---

## Spacing & Layout

### Container Padding

```html
<main class="px-4 lg:px-8">
  <!-- Content -->
</main>

<div class="p-4 lg:p-8">
  <!-- Card content -->
</div>
```

### Grids and Flex Layouts

```html
<!-- Stack on mobile, row on desktop -->
<div class="flex flex-col lg:flex-row gap-4">
  <div class="flex-1">Left</div>
  <div class="flex-1">Right</div>
</div>

<!-- Stack to grid -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
  <div>Card 1</div>
  <div>Card 2</div>
  <div>Card 3</div>
</div>
```

---

## Tables

### Responsive Table Pattern

```html
<div class="overflow-x-auto">
  <table class="w-full border-collapse">
    <thead>
      <tr class="border-b border-black">
        <th class="px-4 lg:px-7 py-3 text-left text-sm lg:text-base">Stock</th>
        <th class="hidden lg:table-cell px-7 py-3 text-right">Price</th>
        <th class="px-4 lg:px-7 py-3 text-right text-sm lg:text-base">Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-b">
        <td class="px-4 lg:px-7 py-2 text-sm lg:text-base">AAPL</td>
        <td class="hidden lg:table-cell px-7 py-2 text-right">$150.00</td>
        <td class="px-4 lg:px-7 py-2 text-right">
          <button class="min-h-[44px] px-4">Buy</button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

---

## Forms

```html
<input
  type="text"
  class="w-full lg:max-w-md px-4 py-3 text-base border rounded-lg"
  placeholder="Enter amount"
/>

<button
  type="submit"
  class="w-full lg:w-auto px-6 py-3 min-h-[48px] bg-blue-600 text-white rounded-lg"
>
  Submit
</button>
```

---

## Images & Media

```html
<img src="piggy-bank.png" class="w-24 lg:w-32 h-auto" alt="Piggy bank">

<div class="overflow-hidden rounded-lg">
  <img src="chart.png" class="w-full h-auto" alt="Stock chart">
</div>
```

---

## Navigation

```html
<input type="checkbox" id="menu-toggle" class="hidden peer" />

<label for="menu-toggle" class="lg:hidden flex items-center justify-center w-10 h-10">
  <svg class="w-6 h-6">...</svg>
</label>

<nav class="fixed top-0 bottom-0 left-0 w-64 transform -translate-x-full peer-checked:translate-x-0 lg:translate-x-0 transition-transform">
  <!-- Nav links -->
</nav>
```

---

## Testing Requirements

### Test the range, not two points

See "Two tiers is not two widths" above for why. The short version: 320, 375, 768, 1024, 1366 and
1920, plus 375 and 1024 at 200% text.

### Checklist

- [ ] No horizontal scroll at any width
- [ ] Nothing lost or unreachable at 200% text
- [ ] Body text is at least 14px
- [ ] Buttons are 40px (`h-10`); reserve 44px for bare tap targets with no other affordance
- [ ] Navigation reachable at every width
- [ ] Contrast measured, not guessed — paint a pixel and read it back, because `getComputedStyle`
      returns `oklch()` here and treating those three numbers as RGB reports nonsense

---

## Common Patterns

### Card

Render `components/ui/_card` rather than hand-rolling one. If you are writing the surface by hand,
it is `rounded-2xl border border-slate-200 bg-white shadow-sm` with `p-5` — not a black 2px border at
a 20px radius, which is pre-token markup and no longer anywhere in the app.

### Button group

```html
<div class="flex flex-col gap-3 lg:flex-row">
  <button class="tw-btn-primary w-full lg:w-auto">Save changes</button>
  <button class="tw-btn-secondary w-full lg:w-auto">Cancel</button>
</div>
```

Full width on a phone, intrinsic width from `lg`. The height comes from `.tw-btn-*`; do not set it
per call site, and do not add a second filled primary — one page, one primary.

### Something whose height depends on its text

```html
<div class="flex min-h-8 items-center justify-center px-4 py-1 text-center leading-tight">
  <span>A sentence that may wrap on a phone.</span>
</div>
```

`min-h-*`, never `h-*`. A fixed height with centred content overflows in **both** directions once the
text is taller than the box, and the half that goes up is unreachable if the element is fixed.

---

## Quick Reference

```
(no prefix) = up to 1023px (mobile-first)
lg:         = 1024px+ (sidebar appears, layouts go multi-column)

no sm: md: xl: 2xl:, and no custom breakpoints

verify at 320 375 768 1024 1366 1920
    and at 375 and 1024 with text at 200%
```

---

## Checklist
- [ ] Uses utilities and the shared `.tw-*` classes; no inline styles, no arbitrary value that has a
      scale equivalent
- [ ] Works continuously from 320px to 1920px, not just at 375 and 1366
- [ ] Nothing lost or unreachable at 200% text
- [ ] No horizontal scroll at any width
- [ ] Buttons 40px; 44px only for bare tap targets
- [ ] Accessible labels, and contrast **measured** rather than assumed

---

## Additional Resources

- [Tailwind CSS Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [WCAG Touch Target Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
- [Mobile-First Design Principles](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Responsive/Mobile_first)
- [WCAG 1.4.10 Reflow](https://www.w3.org/WAI/WCAG21/Understanding/reflow.html)
- [WCAG 1.4.4 Resize Text](https://www.w3.org/WAI/WCAG21/Understanding/resize-text.html)
- [web.dev — add breakpoints based on content](https://web.dev/learn/design/media-queries)

---
