# Type-ahead and multiselect: not implemented, and what to keep from the attempt

**Status: this app has none.** No TomSelect, no type-ahead, no multiselect. Its one long list of people —
the classroom form's teacher picker — is a checkbox group, and its filters are a search field and a
tab rail. Nothing here describes a control you can use today.

This file exists because 279 lines of specification for those controls were deleted from `design.md`, and
deleting a rule and deleting the reasoning behind it are different things.

## Why it was deleted rather than translated

`design.md` was inherited from Ruby for Good's **CASA** project, and those sections specified CASA's
controls: a rich `Form::MultipleSelectComponent`, six person-assignment pickers, an audit of twenty
TomSelect instances, with their file paths and their bugs. Asked to rewrite the examples in this app's
domain, the honest answer was that there was nothing to rewrite them *into* — this app has no such
control, and a specification is an instruction. Left in place, the next person who needed a searchable
picker would have built CASA's.

**Best practice, and the reasoning:** the archive of record is git. The full original is one command
away —

```
git show dffbdc6^:design.md | sed -n '3614,3892p'
```

— and copying it into a file here would create a second copy that drifts and that somebody eventually
reads as current. That is the same hazard this codebase records about unused CSS: *an unused class is
indistinguishable from a supported one until someone adopts it.* So what is preserved below is the
**distillation** — the handful of rules that would apply to any picker, in any framework — and not the
inventory.

## When to build one

**Past roughly ten options**, a checkbox group should become a searchable multi-select with chips —
GitHub's assignees picker, Linear's, Jira's. A list you have to scroll to find a name in is a list you
should be able to type into. The classroom form's teacher picker is where that threshold will be met
first, and it is recorded there too.

## What to keep, if that day comes

Four rules survived the deletion because none of them is about TomSelect:

**Clear the query when an item is picked.** A typed fragment left sitting next to a new chip is the most
common complaint about every multiselect ever shipped, and no library does it for you by default.
Reported on CASA as "the letters the user types stay even after they have made a selection".

**Address the control through its native `<select>`, never through the widget's own DOM.** Widget wrappers
are positional and positions lie: on CASA the first wrapper on a page belonged to a control inside a
closed `<dialog>` — `display: none`, 0×0 — so a test that found "the first one" was driving something
invisible. This app has its own version of that lesson recorded in `CLAUDE.md`, about `querySelector`
returning the hidden copy of a duplicated control.

**Assert filtering by a decoy's absence, never by reading the menu.** A count taken straight after the
keystrokes sees the **pre-filter** DOM, which is how a probe once reported "typing does nothing" about a
control that was filtering 31 options down to 1. Name a fixture that must *not* match and use a waiting
matcher, which retries until the filter lands. The general form of this is in `CLAUDE.md`: a read taken
in the same instant as the change measures the value it is leaving.

**Option subtext must never be nil, and never say "never".** A hint under an option that reads "never"
tells the reader the option is broken rather than unused.
