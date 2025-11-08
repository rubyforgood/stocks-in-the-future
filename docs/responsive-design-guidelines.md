# Responsive Design Guidelines

**Target Users:** Students on Chromebooks  
**Last Updated:** 2025-10-19

---

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
- [Quick Reference](#quick-reference)
- [Checklist](#checklist)
- [Additional Resources](#additional-resources)

---

## Overview

> ✅ Use only `base` and `lg:` responsive tiers.  
> Test all UI components at **375px** and **1366px** before submitting PRs.

These guidelines ensure a consistent, accessible responsive design across the **Stocks in the Future** application.  
All contributors working on responsive features must follow these standards.

**Core Principles**
- 🎯 **Mobile-first:** Design for the smallest screen and scale up.
- 💻 **Chromebook-focused:** 1366×768 is our main target.
- ✋ **Touch-friendly:** Minimum 44px touch targets.
- 🎨 **Tailwind-only:** No custom CSS.
- ♿ **Accessible:** WCAG AA minimum compliance.

---

## Breakpoints

We only support **two responsive tiers**:

| Mode | Screen Size | Tailwind Prefix | Example Devices | Priority |
|------|--------------|----------------|------------------|-----------|
| **Base (mobile)** | up to 1023px | *(no prefix)* | Phones, tablets | Medium |
| **Chromebook/Desktop** | 1024px+ | `lg:` | Chromebooks, desktops | **CRITICAL** |

### Why Only Two?

- 1366×768 is the **most common Chromebook resolution**.
- Simplifies layout logic and testing.
- Matches real classroom usage.
- Keeps Tailwind classes minimal and maintainable.

### Example

```html
<!-- Mobile-first base styles -->
<div class="px-4">Mobile padding</div>

<!-- Add styles for larger screens -->
<div class="px-4 lg:px-8">Responsive padding</div>

<!-- Show/hide elements -->
<div class="lg:hidden">Mobile only</div>
<div class="hidden lg:block">Desktop only</div>
```

---

## Touch Targets

### Minimum Sizes

| Element | Minimum | Preferred | Notes |
|----------|----------|------------|--------|
| Buttons | 44×44px | 48×48px | Use `min-h-[44px]` or larger |
| Inputs | 44px height | 48px height | Use `py-3` minimum |
| Checkboxes | 24×24px | 32×32px | Make label clickable |
| Icon buttons | 44×44px | 48×48px | Hamburger, close, etc. |

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

### Test at Two Sizes

- ✅ 375px — Mobile (base)
- ✅ 1366px — Chromebook (lg)

### Checklist

- [ ] No horizontal scroll
- [ ] Minimum text size 14px
- [ ] All touch targets ≥44px
- [ ] Forms and buttons are touch-friendly
- [ ] Navigation accessible
- [ ] Layout consistent on Chromebook

---

## Common Patterns

### Card

```html
<div class="bg-white border-2 border-black rounded-[20px] p-4 lg:p-8">
  <h2 class="text-xl lg:text-3xl font-bold mb-4">Card Title</h2>
  <p class="text-base lg:text-lg">Card content</p>
</div>
```

### Button Group

```html
<div class="flex flex-col lg:flex-row gap-3">
  <button class="w-full lg:w-auto px-6 py-3 min-h-[48px] bg-blue-600 text-white rounded-lg">Primary</button>
  <button class="w-full lg:w-auto px-6 py-3 min-h-[48px] border-2 border-black rounded-lg">Secondary</button>
</div>
```

---

## Quick Reference

```
(no prefix) = up to 1023px (mobile-first)
lg: = 1024px+ (Chromebook/Desktop)
```

---

## Checklist
- [ ] Uses Tailwind-only classes
- [ ] Works at 375px and 1366px
- [ ] No horizontal scroll
- [ ] All touch targets ≥44px
- [ ] Accessible labels and contrast

---

## Additional Resources

- [Tailwind CSS Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [WCAG Touch Target Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
- [Mobile-First Design Principles](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Responsive/Mobile_first)

---
