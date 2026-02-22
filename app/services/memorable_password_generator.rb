# frozen_string_literal: true

# TODO: more robust solution later.
class MemorablePasswordGenerator
  RANGE = (1..99)

  class << self
    def generate
      password = Faker::Superhero.name + rand(RANGE).to_s + Faker::Superhero.name
      normalize password
    end

    private

    def normalize(password)
      invalid_characters = [" ", "-", "'"]
      invalid_characters.each { password.delete! it }
      password
    end
  end
end
