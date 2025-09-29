# frozen_string_literal: true

ActiveSupport.on_load(:action_view) { include LucideRails::LucideHelper } if defined?(LucideRails::LucideHelper)
