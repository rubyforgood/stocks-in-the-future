# frozen_string_literal: true

# The tertiary (ghost) control, and the row actions built on it. One definition, shared by the
# app and admin tables, because copy-pasted inline strings drift: before this existed the same
# three actions were written six different ways across nine tables - View as `tw-link` in five
# of them and `text-sitf-primary-dark hover:underline` in a sixth, Edit as `text-slate-600` or
# `text-slate-700`, Delete as `text-red-600` in four and `font-medium text-red-700` in another.
#
# Ghost is the lowest-emphasis button: no border, fill or shadow. A filled CTA repeated down
# every row of a table over-emphasises a per-row action and breaks table-to-table consistency,
# so a row action is never `.tw-btn-primary` / `.tw-btn-secondary`.
module ButtonHelper
  # 32px at every width. 28-32px is where table row actions sit in current practice (GitHub
  # Primer's small control is 28, its medium 32; Linear and Stripe about 28; Polaris slim 28), and
  # holding 44px anywhere would make a ghost taller than the 40px primary button it is supposed to
  # recede from.
  #
  # This was min-h-11 below lg, on a "44px where the finger is" argument that contradicted the
  # app's own rule: 44px is reserved for *bare* tap targets with no other affordance - an icon-only
  # control, a sidebar nav row - and this has a visible label and about 80px of width. Fitts's law
  # cares about both dimensions. WCAG 2.5.8 (AA) asks 24x24, which 32px clears.
  #
  # It also read wrong. In a cell whose neighbours are 17px lines of text, a 44px box top-aligned to
  # the row's first line extends 27px past it and looks like a slab floating mid-row - reported on
  # the portfolio holdings table, whose rows reach 100px at 375px because the company name wraps. At
  # 32px the button's top sits within a pixel of the text's.
  GHOST_BASE = "inline-flex min-h-8 items-center gap-1.5 rounded-lg px-2 py-1 " \
               "text-sm font-medium transition-colors focus-visible:outline-2 " \
               "focus-visible:outline-offset-2"

  # Both variants are slate at rest and differ only on hover. A column of red "Delete" links is
  # an always-on alarm, and it makes the destructive action the most eye-catching thing in the
  # table; slate-at-rest plus rose-on-hover reveals the danger at the point of action instead,
  # which is what GitHub, Gmail and Linear do. The danger is also carried by the trash icon, the
  # label and the confirm dialog - never by colour alone (WCAG 1.4.1).
  #
  # Measured on white: slate-600 7.58:1, and 7.24:1 on the slate-50 row hover it sits over.
  # Hover states: slate-900 on slate-100 16.30:1, rose-700 on rose-50 5.72:1.
  def ghost_class(variant = :neutral)
    state = case variant.to_sym
            when :danger
              "text-slate-600 hover:bg-rose-50 hover:text-rose-700 focus-visible:outline-rose-700"
            else
              "text-slate-600 hover:bg-slate-100 hover:text-slate-900 " \
              "focus-visible:outline-sitf-primary"
            end

    "#{GHOST_BASE} #{state}"
  end

  # A table row action: ghost shape, leading icon, visible label.
  #
  # The icon is not decoration that can be forgotten - it is what makes a dense column of
  # actions scannable, and for Delete it is half of the redundant coding that keeps the meaning
  # off colour. Rendering it here rather than at each call site is what stops it going missing.
  #
  # lucide_icon is aria-hidden, so the label carries the accessible name.
  def ghost_action_link(label, path, icon:, variant: :neutral, **options)
    link_to path, **ghost_options(options, variant) do
      safe_join([ghost_icon(icon), label])
    end
  end

  # The same control where the action needs a real form submit rather than a link - a
  # `button_to`. Note this renders a whole <form>, so it must never sit inside another one.
  def ghost_action_button(label, path, icon:, variant: :neutral, **options)
    form_options = options.delete(:form) || {}

    button_to path, **ghost_options(options, variant), form: form_options do
      safe_join([ghost_icon(icon), label])
    end
  end

  # The same two controls as a **menu item**: full width, 44px, label after the icon. A row's actions
  # inside `components/ui/_row_actions` use these rather than the ghosts, because a ghost is sized to its
  # own content and a menu row fills the panel.
  def menu_action_link(label, path, icon:, variant: :neutral, **options)
    link_to path, **menu_options(options, variant) do
      safe_join([ghost_icon(icon), label])
    end
  end

  # Renders a whole `<form>`, so it must not sit inside another one. A popover panel is not a form, and a
  # table row is not a form, so this is safe in a row actions menu - but it is the reason the callout's
  # dismiss is passed per call site rather than built into that component.
  def menu_action_button(label, path, icon:, variant: :neutral, **options)
    form_options = options.delete(:form) || {}

    button_to path, **menu_options(options, variant), form: form_options do
      safe_join([ghost_icon(icon), label])
    end
  end

  private

  def menu_options(options, variant)
    classes = ["tw-menu-item", ("tw-menu-item-danger" if variant == :danger), options[:class]]
    options.merge(class: classes.compact.join(" "))
  end

  def ghost_icon(icon)
    lucide_icon(icon, class: "size-4 shrink-0")
  end

  # Merges rather than overwrites, so a call site can add its own classes without losing the
  # ghost, and cannot accidentally drop the variant by passing class:.
  def ghost_options(options, variant)
    options.merge(class: [ghost_class(variant), options[:class]].compact.join(" "))
  end
end
