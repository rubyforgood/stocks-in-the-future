class Student < User
    belongs_to :classroom
    has_one :portfolio, foreign_key: 'user_id'

    # Student can get their portfolio
    def get_portfolio
        self.portfolio
    end
end