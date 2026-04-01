# frozen_string_literal: true

class Classroom < ApplicationRecord
  MIN_GRADE = 5
  MAX_GRADE = 8
  GRADE_RANGE = (MIN_GRADE..MAX_GRADE).to_a.freeze

  belongs_to :school_year
  has_one :school, through: :school_year
  has_one :year, through: :school_year

  delegate :name, to: :school, prefix: :school
  delegate :name, to: :year, prefix: :year

  has_many :users, dependent: :nullify
  has_many :teacher_classrooms, dependent: :destroy
  has_many :teachers, through: :teacher_classrooms
  has_many :classroom_enrollments, dependent: :destroy
  has_many :enrolled_students, through: :classroom_enrollments, source: :student
  has_many :students, -> { kept }, class_name: "Student", inverse_of: :classroom, dependent: :nullify
  has_many :classroom_grades, dependent: :destroy
  has_many :grades, through: :classroom_grades
  has_many :grade_books, dependent: :nullify

  validates :name, presence: true
  validate :school_year_presence
  validate :grade_level

  after_create :create_gradebooks_for_quarters

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :order_by_name, ->(direction = :asc) { reorder(name: direction) }
  scope :order_by_student_count, lambda { |direction = :asc|
    dir = direction.to_s.upcase == "DESC" ? "DESC" : "ASC"

    joins("LEFT OUTER JOIN users ON users.classroom_id = classrooms.id AND users.type = 'Student'")
      .group(:id)
      .order(Arel.sql("COUNT(users.id) #{dir}"))
  }
  scope :order_by_total_earnings, lambda { |direction = :asc|
    dir = direction.to_s.upcase == "DESC" ? "DESC" : "ASC"

    joins("LEFT OUTER JOIN users ON users.classroom_id = classrooms.id AND users.type = 'Student'")
      .joins("LEFT OUTER JOIN portfolios ON portfolios.user_id = users.id")
      .joins("LEFT OUTER JOIN portfolio_transactions ON portfolio_transactions.portfolio_id = portfolios.id")
      .group(:id)
      .order(Arel.sql("COALESCE(SUM(portfolio_transactions.amount_cents), 0) #{dir}"))
  }

  # Apply sorting based on sort column param
  # @param collection [ActiveRecord::Relation] The collection to sort (optional)
  # @param sort_column [String] The column to sort by
  # @param direction [Symbol] :asc or :desc
  # @return [ActiveRecord::Relation] The sorted collection
  def self.apply_sorting(collection = nil, sort_column = nil, direction = :asc)
    base_scope = collection || all

    case sort_column
    when "name"
      base_scope.order_by_name(direction)
    when "student_count"
      base_scope.order_by_student_count(direction)
    when "total_earnings"
      base_scope.order_by_total_earnings(direction)
    else
      base_scope.order_by_name(:asc)
    end
  end

  # Get currently enrolled students (students with active enrollments)
  #
  # @return [ActiveRecord::Relation<Student>]
  def current_students
    enrolled_students.joins(:classroom_enrollments)
      .merge(classroom_enrollments.current)
      .distinct
  end

  # Get historically enrolled students (students with past enrollments)
  #
  # @return [ActiveRecord::Relation<Student>]
  def historical_students
    enrolled_students.joins(:classroom_enrollments)
      .merge(classroom_enrollments.historical)
      .distinct
  end

  def grades_display
    values = classroom_grades
      .joins(:grade)
      .pluck("grades.level")
      .uniq
      .sort
    return if values.empty?

    if values.one?
      values.first.ordinalize
    elsif continuous?(values)
      "#{values.first.ordinalize}-#{values.last.ordinalize}"
    else
      values.map(&:ordinalize).join(", ")
    end
  end

  def continuous?(values)
    values.each_cons(2).all? { |a, b| b == a + 1 }
  end

  private

  def create_gradebooks_for_quarters
    school_year.quarters.each do |quarter|
      GradeBook.find_or_create_by!(quarter: quarter, classroom: self)
    end
  end

  def grade_level
    errors.add(:grades, "must have at least one grade") if grades.empty?
  end

  def school_year_presence
    errors.add(:school_year_id, :blank) if school_year_id.blank? && school_year.nil?
  end
end
