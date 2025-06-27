# frozen_string_literal: true

json.array! @schools, partial: "schools/school", as: :school
