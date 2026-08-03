# frozen_string_literal: true

# One sidebar row treatment, shared by the app nav (layouts/_navbar) and the admin nav
# (admin/shared/_navigation), so moving between the two is not a change of scenery.
#
# The app sidebar used to be a saturated teal panel with the lime chart accent as a full-fill
# selected state, while admin was already white with no selected state at all. Same product,
# two chromes. Both are white now, with the selected row carrying a brand tint and a 3px
# leading indicator - the Stripe / Linear / GitHub / Material 3 treatment, and what a light
# sidebar means in current practice.
#
# Measured: sitf-primary-dark on the blended tint (#e6f0f4 over white) is 7.78:1. The lime it
# replaces was readable at 8.80:1 but is labelled fill-only for charts in the token file, and
# it was the loudest colour in the palette carrying the most repeated state in the app.
module NavHelper
  NAV_ROW_BASE = "flex min-h-11 w-full items-center gap-3 rounded-lg py-2 pr-3 text-sm " \
                 "font-medium transition-colors focus-visible:outline-2 " \
                 "focus-visible:outline-offset-2 focus-visible:outline-sitf-primary"

  def nav_row_class(active:)
    state = if active
              "bg-sitf-primary/10 text-sitf-primary-dark"
            else
              "text-slate-700 hover:bg-slate-100 hover:text-slate-900"
            end

    "#{NAV_ROW_BASE} #{state}"
  end

  # The leading indicator. It keeps its 3px width when inactive, with a transparent colour, so
  # selecting a row does not shift the label sideways.
  def nav_indicator_class(active:)
    "h-5 shrink-0 border-l-[3px] #{active ? 'border-sitf-primary' : 'border-transparent'}"
  end

  # Icons inherit this rather than being tinted by a CSS filter - see navbar.css, where two
  # filter chains existed only because the icons were external SVG assets on a dark panel.
  def nav_icon_class(active:)
    "h-5 w-5 shrink-0 #{active ? 'text-sitf-primary' : 'text-slate-500'}"
  end

  # An admin section is current when the request is inside it, so a show or edit page keeps its
  # parent row highlighted.
  #
  # exact: for a path that is a prefix of every other one. /admin is the Dashboard, and
  # "inside it" would be true on every admin page, so Dashboard lit up everywhere until this
  # existed. A structure test caught it by counting aria-current.
  def nav_section_active?(path, exact: false)
    return request.path == path if exact

    request.path == path || request.path.start_with?("#{path}/")
  end
end
