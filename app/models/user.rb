class User < ApplicationRecord
end

class Admin < User
end

class Teacher < User
end

class Student < User
    belongs_to :classroom
    has_one :portfolio

    # Student can get their portfolio
    def get_portfolio
        self.portfolio
    end
end
