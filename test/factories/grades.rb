# frozen_string_literal: true

# Grade#level is validated unique, and the classroom factory builds a grade for every
# classroom it creates, so this sequence runs constantly.
#
# It used to be `sequence(:level) { |n| n }` - 1, 2, 3 - which walks straight into the levels
# tests hard-code: 5, 6, 7, 9 and 10 across eleven call sites. When the sequence happened to
# reach one of those in the same worker before the test that hard-codes it, the test failed with
# "Validation failed: Level has already been taken". Whether it did depended on the seed and on
# how the 744 tests were spread across ten workers, so it surfaced perhaps once in twenty runs
# and passed on rerun - which is the worst kind of failure to leave for someone else.
#
# Starting at 1000 puts generated levels outside the range real data or a test would name; real
# grade levels are 1 to 12.
FactoryBot.define do
  factory :grade do
    sequence(:level) { |n| 1000 + n }
    sequence(:name)  { |n| "Grade #{n}" }
  end
end
