# frozen_string_literal: true

class FriendlyPasswordGenerator
  ADJECTIVES = %w[happy quick brave smart cool nice warm bright fresh clean].freeze
  NOUNS = %w[bird moon star tree fish cat dog bear wolf fox].freeze

  def self.generate
    adjective = ADJECTIVES.sample
    noun = NOUNS.sample
    numbers = rand(10..99)

    "#{adjective}#{numbers}#{noun}"
  end
end
