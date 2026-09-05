# frozen_string_literal: true

# Grade#level is unique, and tests that care about a level hard code a real one
# (a classroom of 9th and 10th graders, say). Counting the sequence from 1 ran it
# straight through that range, so a test asking for level 7 failed whenever its
# worker had already built seven grades. Sequences are per process and survive
# the transaction rollback between tests, so whether it collided depended on the
# seed and the parallel split. Start above any level a school would use, so a
# generated level and a hard coded one can never meet.
FIRST_GENERATED_GRADE_LEVEL = 100

FactoryBot.define do
  factory :grade do
    sequence(:level) { |n| FIRST_GENERATED_GRADE_LEVEL + n }
    sequence(:name)  { |n| "Grade #{n}" }
  end
end
