# frozen_string_literal: true

# The staging ribbon, and the one place its geometry is written down.
#
# An admin on staging had nothing on screen telling them the data was not real. A ribbon answers "which
# deployment am I looking at", which is a different question from the component demo's banner - that one
# says "this *page* is not part of the product", and it stays.
#
# **Staging only, never development.** In development the URL already says localhost, and a permanent
# stripe on every page of every working day is noise that teaches you to stop seeing it - which is
# exactly what would make it useless on staging, where it is seen rarely and has to register.
#
# It is a strip above the header rather than a callout in the content, because it describes the whole
# application and not the page - GitLab's environment ribbon and Shopify's development-store banner sit
# in the chrome for the same reason. And it has no dismiss: this app's rule is that only an *outcome*
# removes itself, and the environment is still true in a minute.
module EnvironmentHelper
  RIBBON_HEIGHT = "2rem" # h-8, and the offset every fixed element below it needs

  def environment_ribbon?
    Rails.env.staging?
  end

  # The fixed header sits at the top, or below the ribbon. Both layouts read this, so the offset is
  # written once - a second copy would be the fourth thing this codebase has watched drift.
  def header_top_class
    environment_ribbon? ? "top-8" : "top-0"
  end

  # `main` clears the 64px header, plus the ribbon when there is one.
  def main_offset_class(property)
    if environment_ribbon?
      property == :margin ? "mt-24" : "pt-24"
    else
      property == :margin ? "mt-16" : "pt-16"
    end
  end

  # The admin drawer hangs off the bottom of the header.
  def drawer_top_class
    environment_ribbon? ? "top-24" : "top-16"
  end

  def drawer_height_class
    environment_ribbon? ? "h-[calc(100vh-6rem)]" : "h-[calc(100vh-4rem)]"
  end
end
