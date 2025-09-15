# frozen_string_literal: true

# Include main Tailwind build in Administrate so admin dashboard gets project CSS classes.
Administrate::Engine.stylesheets.delete("tailwind")
Administrate::Engine.stylesheets << "tailwind"
