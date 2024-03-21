class User < ApplicationRecord
end

class Admin < User
end

class Teacher < User
end

class Student < User
    belongs_to :classroom
    has_one :portfolio
end
