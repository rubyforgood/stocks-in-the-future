# frozen_string_literal: true

# The staging ribbon: which deployment am I looking at.
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
#
# This used to carry five methods handing out Tailwind classes - `header_top_class`,
# `main_offset_class`, `drawer_top_class`, `drawer_height_class`, `sidebar_top_class` - so that the
# ribbon's 32px was written down in six places. Two things went wrong with that and both are recorded
# in chrome.css: one layout did not use them, and a hardcoded height cannot survive 200% text. The
# offsets are CSS now, driven by the ribbon's measured height, and this is back to one question.
module EnvironmentHelper
  # Set `PREVIEW_STAGING_CHROME=1` to see it locally. Chrome that only exists in one environment is
  # chrome nobody looks at until it is deployed, which is how it reached staging with the app side's
  # sidebar 32px behind the header and its text unreachable at 200%. Refused in production, where the
  # ribbon would be an outright lie.
  def environment_ribbon?
    return true if ENV["PREVIEW_STAGING_CHROME"] == "1" && !Rails.env.production?

    Rails.env.staging?
  end
end
