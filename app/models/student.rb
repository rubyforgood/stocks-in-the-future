class Student < User
    belongs_to :classroom
    has_one :portfolio, foreign_key: 'user_id'
end