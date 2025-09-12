# frozen_string_literal: true

# TODO: more robust solution later.
class MemorablePasswordGenerator
  NUMBERS = (1..99).to_a.freeze

  def self.generate
    (Faker::Superhero.name + rand(1..99).to_s + Faker::Superhero.name).delete(" ").delete("-")
  end
end
