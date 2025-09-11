# frozen_string_literal: true

# TODO: more robust solution later.
class MemorablePasswordGenerator
  WORDS = %w[Sunset Moonlight Spring Autumn River Glade Mountain Valley].freeze
  NUMBERS = (1..99).to_a.freeze

  def self.generate
    "#{WORDS.sample}#{NUMBERS.sample}"
  end
end
