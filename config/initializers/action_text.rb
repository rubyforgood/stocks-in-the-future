# frozen_string_literal: true

# Action Text configuration
Rails.application.configure do
  config.after_initialize do
    ActionText::RichText.table_name = "action_text_rich_texts"
  end
end