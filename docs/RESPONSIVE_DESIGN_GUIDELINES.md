# Responsive Design Guidelines

**Target Users: Students on Chromebooks**
**Last Updated: 2025-01-19**

## Table of Contents
- [Overview](#overview)
- [Breakpoints](#breakpoints)
- [Touch Targets](#touch-targets)
- [Typography](#typography)
- [Spacing & Layout](#spacing--layout)
- [Tables](#tables)
- [Forms](#forms)
- [Images & Media](#images--media)
- [Navigation](#navigation)
- [Testing Requirements](#testing-requirements)
- [Common Patterns](#common-patterns)

---

## Overview

These guidelines ensure a consistent, accessible responsive design across the Stocks in the Future application. All contributors working on responsive features must follow these standards.

**Core Principles:**
- 🎯 **Mobile-first**: Design for smallest screen, scale up
- 📱 **Chromebook-focused**: 1366x768 is our primary target
- ✋ **Touch-friendly**: Minimum 44px touch targets
- 🎨 **Tailwind-only**: No custom CSS classes
- ♿ **Accessible**: WCAG AA compliance minimum

---

## Breakpoints

### Test at These Specific Sizes

Use Chrome DevTools responsive mode (Cmd+Shift+M / Ctrl+Shift+M):

| Breakpoint | Size | Device | Tailwind Prefix | Priority |
|------------|------|--------|-----------------|----------|
| Mobile | **375px** | iPhone SE, small Android | `base` | Medium |
| Tablet | **768px** | iPad, Android tablet | `sm:` | Medium |
| Large Tablet | **1024px** | iPad Pro, small Chromebook | `lg:` | High |
| **Chromebook** | **1366px** | **Typical Chromebook** | `xl:` | **CRITICAL** |
| Desktop | 1920px+ | Desktop monitors | `2xl:` | Low |

### Why 1366px is Critical

- **Most common Chromebook resolution** (1366x768)
- Students use these devices daily in classrooms
- Cannot rely on "just zoom out" - affects usability and grading
- Budget-friendly Chromebooks are standard in education

### Tailwind Breakpoint Reference

```html
<!-- Mobile first: base styles apply to all sizes -->
<div class="px-4">           <!-- 16px padding on all sizes -->

<!-- Add styles at larger breakpoints -->
<div class="px-4 sm:px-6">  <!-- 16px mobile, 24px at 640px+ -->
<div class="px-4 lg:px-8">  <!-- 16px mobile, 32px at 1024px+ -->

<!-- Hide/show at different sizes -->
<div class="hidden lg:block"> <!-- Hidden on mobile, visible at 1024px+ -->
<div class="lg:hidden">        <!-- Visible on mobile, hidden at 1024px+ -->
</div>
```

---

## Touch Targets

### Minimum Sizes

**All interactive elements must meet these minimums:**

| Element Type | Minimum Size | Preferred Size | Notes |
|--------------|--------------|----------------|-------|
| Buttons (Primary) | 44x44px | 48x48px | Use `min-h-[44px]` or larger |
| Buttons (Secondary) | 44x44px | 44x44px | Icons need adequate padding |
| Links (Text) | 44px height | 48px height | Increase line-height or padding |
| Form Inputs | 44px height | 48px height | Use `py-3` minimum |
| Checkboxes/Radio | 24x24px | 32x32px | Ensure label is also clickable |
| Icon-only Buttons | 44x44px | 48x48px | Hamburger menu, close buttons |

### Touch Target Spacing

```html
<!-- Minimum 8px spacing between touch targets -->
<div class="flex gap-2">  <!-- 8px gap -->
  <button class="min-h-[44px] px-4">Action 1</button>
  <button class="min-h-[44px] px-4">Action 2</button>
</div>

<!-- Preferred 12-16px spacing -->
<div class="flex gap-4">  <!-- 16px gap -->
  <button class="min-h-[48px] px-6">Primary</button>
  <button class="min-h-[48px] px-6">Secondary</button>
</div>
```

### Examples

✅ **Good:**
```html
<!-- Hamburger button: 40x40px (acceptable) with adequate padding -->
<button class="w-10 h-10 flex items-center justify-center">
  <svg class="w-6 h-6">...</svg>
</button>

<!-- Primary action: 48px height -->
<button class="px-6 py-3 min-h-[48px]">Buy Stock</button>
```

❌ **Bad:**
```html
<!-- Too small: 32x32px -->
<button class="w-8 h-8">×</button>

<!-- Text link with insufficient padding -->
<a href="#" class="text-sm">Click here</a>
```

---

## Typography

### Scale by Breakpoint

| Purpose | Mobile (375px) | Tablet (768px) | Desktop (1366px+) |
|---------|----------------|----------------|-------------------|
| H1 (Page Title) | `text-2xl` (24px) | `text-3xl` (30px) | `text-4xl` (36px) |
| H2 (Section) | `text-xl` (20px) | `text-2xl` (24px) | `text-3xl` (30px) |
| H3 (Subsection) | `text-lg` (18px) | `text-xl` (20px) | `text-2xl` (24px) |
| Body Text | `text-base` (16px) | `text-base` (16px) | `text-lg` (18px) |
| Small Text | `text-sm` (14px) | `text-sm` (14px) | `text-base` (16px) |
| Labels/Captions | `text-xs` (12px) | `text-sm` (14px) | `text-sm` (14px) |

### Rules

1. **Never go below 14px (`text-sm`) for body text** - accessibility requirement
2. **Never go below 12px (`text-xs`)** - even for labels/metadata
3. **Use responsive classes**: `text-2xl sm:text-3xl lg:text-4xl`
4. **Maintain hierarchy** - ensure headings are always larger than body

### Examples

```html
<!-- Page title: scales from 24px → 30px → 36px -->
<h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold">
  Welcome to Your Financial Journey
</h1>

<!-- Body text: 16px on all sizes (readable baseline) -->
<p class="text-base">
  This is your launchpad to earn, invest, and grow.
</p>

<!-- Small metadata: 12px mobile → 14px desktop -->
<span class="text-xs sm:text-sm text-gray-500">
  Last updated: 2 hours ago
</span>
```

---

## Spacing & Layout

### Container Padding

```html
<!-- Page wrapper: responsive horizontal padding -->
<main class="px-4 sm:px-6 lg:px-8">
  <!-- Content -->
</main>

<!-- Card/Section: consistent internal padding -->
<div class="p-4 sm:p-6 lg:p-8">
  <!-- Card content -->
</div>
```

### Margins & Gaps

| Purpose | Mobile | Desktop | Tailwind Class |
|---------|--------|---------|----------------|
| Between sections | 16px (4) | 24px (6) | `mb-4 sm:mb-6` |
| Between cards | 12px (3) | 16px (4) | `gap-3 sm:gap-4` |
| Between elements | 8px (2) | 12px (3) | `gap-2 sm:gap-3` |
| Tight spacing | 4px (1) | 8px (2) | `gap-1 sm:gap-2` |

### Grid Layouts

```html
<!-- Stack on mobile, 2 columns on tablet, 3 on desktop -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <div>Card 1</div>
  <div>Card 2</div>
  <div>Card 3</div>
</div>

<!-- Stack on mobile, side-by-side on desktop -->
<div class="flex flex-col lg:flex-row gap-4">
  <div class="flex-1">Left</div>
  <div class="flex-1">Right</div>
</div>
```

---

## Tables

### Responsive Table Pattern

**Always wrap tables in horizontal scroll container:**

```html
<div class="overflow-x-auto">
  <table class="w-full">
    <thead>...</thead>
    <tbody>...</tbody>
  </table>
</div>
```

### Rules

1. ✅ **Use `overflow-x-auto`** on container, not table
2. ✅ **Remove fixed widths** (`min-w-[700px]`) - let content determine width
3. ✅ **Responsive padding**: `px-4 lg:px-7` on cells
4. ✅ **Responsive text**: `text-xs sm:text-sm lg:text-base`
5. ❌ **Don't use horizontal scroll as primary design** - it's a fallback

### Mobile-Specific Table Considerations

For tables with 5+ columns, consider:
- Hiding less critical columns on mobile: `hidden lg:table-cell`
- Using responsive text: `text-xs sm:text-sm`
- Reducing cell padding: `px-2 sm:px-4 lg:px-7`

### Example

```html
<!-- Table container -->
<div class="overflow-x-auto">
  <table class="w-full border-collapse">
    <thead>
      <tr class="border-b border-black">
        <!-- Always visible column -->
        <th class="px-4 lg:px-7 py-3 text-left text-xs sm:text-sm">
          Stock
        </th>
        <!-- Hide on mobile, show on desktop -->
        <th class="hidden lg:table-cell px-7 py-3 text-right">
          Price
        </th>
        <!-- Always visible -->
        <th class="px-4 lg:px-7 py-3 text-right text-xs sm:text-sm">
          Actions
        </th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-b">
        <td class="px-4 lg:px-7 py-2 text-xs sm:text-sm">AAPL</td>
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

### Input Sizing

```html
<!-- Full width on mobile, constrained on desktop -->
<input
  type="text"
  class="w-full lg:max-w-md px-4 py-3 text-base border rounded-lg"
  placeholder="Enter amount"
>

<!-- Adequate padding for touch targets -->
<button
  type="submit"
  class="w-full lg:w-auto px-6 py-3 min-h-[48px] bg-blue-600 text-white rounded-lg"
>
  Submit Order
</button>
```

### Form Layout

```html
<!-- Stack labels above inputs on mobile -->
<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium mb-2">Number of Shares</label>
    <input
      type="number"
      class="w-full px-4 py-3 border rounded-lg"
      required
      min="1"
    >
  </div>

  <div>
    <label class="block text-sm font-medium mb-2">Price</label>
    <input
      type="number"
      class="w-full px-4 py-3 border rounded-lg"
      required
      step="0.01"
    >
  </div>
</div>
```

### Form Validation

1. **Always use HTML5 validation attributes**: `required`, `min`, `max`, `pattern`
2. **Show error messages clearly**: Red text, adequate padding
3. **Ensure error messages are readable**: Minimum `text-sm`

---

## Images & Media

### Responsive Sizing

```html
<!-- Scale image size with breakpoint -->
<img
  src="piggy-bank.png"
  class="w-24 sm:w-28 lg:w-32 h-auto"
  alt="Piggy bank"
>

<!-- Maintain aspect ratio -->
<img
  src="chart.png"
  class="w-full h-auto"
  alt="Stock chart"
>
```

### Container Rules

```html
<!-- Allow intentional overflow (e.g., decorative elements) -->
<div class="relative overflow-visible">
  <img
    src="decorative.png"
    class="absolute -top-8 right-0 w-32"
    alt=""
  >
</div>

<!-- Prevent overflow for content images -->
<div class="overflow-hidden rounded-lg">
  <img src="content.jpg" class="w-full h-auto" alt="Description">
</div>
```

---

## Navigation

### Mobile Menu Pattern

Use CSS-only checkbox hack (no JavaScript):

```html
<!-- Hidden checkbox for state -->
<input type="checkbox" id="mobile-menu-toggle" class="hidden peer" />

<!-- Hamburger button (mobile only) -->
<label
  for="mobile-menu-toggle"
  class="lg:hidden cursor-pointer flex items-center justify-center w-10 h-10"
>
  <svg class="w-6 h-6">...</svg>
</label>

<!-- Overlay (shows when checked) -->
<label
  for="mobile-menu-toggle"
  class="fixed inset-0 bg-black/50 hidden peer-checked:block lg:hidden"
></label>

<!-- Sidebar (slides in when checked) -->
<nav class="fixed top-0 bottom-0 left-0 w-64
            transform -translate-x-full peer-checked:translate-x-0
            lg:translate-x-0 transition-transform">
  <!-- Nav content -->
</nav>
```

### Navigation Links

```html
<!-- Wrap nav links in label to close menu on click -->
<label for="mobile-menu-toggle" class="lg:cursor-default cursor-pointer">
  <a href="/home" class="flex items-center px-3 py-3 min-h-[44px]">
    Home
  </a>
</label>
```

---

## Testing Requirements

### Before Submitting PR

**1. Test at ALL Breakpoints:**

Open Chrome DevTools (Cmd+Shift+M / Ctrl+Shift+M) and test:
- ✅ 375px - Mobile phone
- ✅ 768px - Tablet
- ✅ 1024px - Large tablet
- ✅ **1366px - Chromebook (CRITICAL)**

**2. Verification Checklist:**

- [ ] No horizontal scroll at any breakpoint
- [ ] All text readable (minimum 14px)
- [ ] All interactive elements 44x44px minimum
- [ ] Images/media scale appropriately
- [ ] Forms usable with touch
- [ ] Navigation accessible
- [ ] Content hierarchy maintained
- [ ] No overlapping elements
- [ ] Adequate whitespace/padding
- [ ] Desktop layout unchanged or improved

**3. Screenshot Requirements:**

Include in PR description:
- Screenshots at all 4 breakpoints
- Mobile menu open state (if applicable)
- Before/after comparison (if fixing bugs)

**4. Code Quality:**

```bash
bin/dc rubocop -A
bin/dc rails test
```

---

## Common Patterns

### Responsive Card

```html
<div class="bg-white border-2 border-black rounded-[20px] p-4 sm:p-6 lg:p-8">
  <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold mb-4">
    Card Title
  </h2>
  <p class="text-base sm:text-lg">
    Card content goes here
  </p>
</div>
```

### Responsive Button Group

```html
<!-- Stack on mobile, row on desktop -->
<div class="flex flex-col sm:flex-row gap-3">
  <button class="w-full sm:w-auto px-6 py-3 min-h-[48px] bg-blue-600 text-white rounded-lg">
    Primary
  </button>
  <button class="w-full sm:w-auto px-6 py-3 min-h-[48px] border-2 border-black rounded-lg">
    Secondary
  </button>
</div>
```

### Responsive Stats Grid

```html
<!-- 1 column mobile, 3 columns desktop -->
<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
  <div class="p-4 bg-white border-2 border-black rounded-lg">
    <div class="text-2xl font-bold">$1,234</div>
    <div class="text-sm text-gray-600">Total Value</div>
  </div>
  <!-- Repeat for other stats -->
</div>
```

### Hide/Show Pattern

```html
<!-- Show on mobile only -->
<div class="lg:hidden">
  Mobile content
</div>

<!-- Hide on mobile, show on desktop -->
<div class="hidden lg:block">
  Desktop content
</div>

<!-- Show different content at different sizes -->
<div class="block sm:hidden">Mobile: Simple view</div>
<div class="hidden sm:block lg:hidden">Tablet: Medium view</div>
<div class="hidden lg:block">Desktop: Full view</div>
```

---

## Quick Reference

### Tailwind Responsive Prefixes

```
(no prefix) = all sizes (mobile-first base)
sm:  = 640px and up
md:  = 768px and up
lg:  = 1024px and up (Chromebook threshold)
xl:  = 1280px and up
2xl: = 1536px and up
```

### Common Responsive Classes

```html
<!-- Padding -->
px-4 sm:px-6 lg:px-8

<!-- Text Size -->
text-2xl sm:text-3xl lg:text-4xl

<!-- Grid -->
grid-cols-1 sm:grid-cols-2 lg:grid-cols-3

<!-- Flex Direction -->
flex-col lg:flex-row

<!-- Hide/Show -->
hidden lg:block
lg:hidden

<!-- Width -->
w-full lg:w-1/2
w-24 sm:w-32 lg:w-40
```

---

## Additional Resources

- [Tailwind CSS Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [WCAG Touch Target Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
- [Mobile-First Design Principles](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Responsive/Mobile_first)

---
