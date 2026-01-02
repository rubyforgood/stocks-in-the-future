# frozen_string_literal: true

class Student < User
  has_many :classroom_enrollments, dependent: :destroy
  has_many :classrooms, through: :classroom_enrollments

  # Ensure students have nil email by default (not empty string)
  after_initialize :set_default_email, if: :new_record?
  after_create :ensure_portfolio
  after_create :create_initial_enrollment, if: -> { classroom_id.present? }

  delegate :path, to: :portfolio, prefix: true, allow_nil: true

  # Get the student's current (active) enrollments
  #
  # @return [ActiveRecord::Relation<ClassroomEnrollment>]
  def current_enrollments
    classroom_enrollments.current
  end

  # Get the student's current (active) classrooms
  #
  # @return [ActiveRecord::Relation<Classroom>]
  def current_classrooms
    classrooms.joins(:classroom_enrollments)
              .merge(classroom_enrollments.current)
              .distinct
  end

  # Get the student's primary enrollment
  #
  # @return [ClassroomEnrollment, nil]
  def primary_enrollment
    classroom_enrollments.primary_enrollment.current.first
  end

  # Get the student's primary classroom (for backward compatibility)
  # Falls back to classroom_id if no primary enrollment exists
  #
  # @return [Classroom, nil]
  def primary_classroom
    primary_enrollment&.classroom || classroom
  end

  # Enroll the student in a classroom
  #
  # @param classroom [Classroom] the classroom to enroll in
  # @param enrolled_at [DateTime] when the student enrolled (defaults to now)
  # @param primary [Boolean] whether this should be the primary enrollment
  # @return [ClassroomEnrollment]
  def enroll_in!(classroom, enrolled_at: Time.current, primary: false)
    enrollment = classroom_enrollments.create!(
      classroom: classroom,
      enrolled_at: enrolled_at,
      primary: primary
    )
    enrollment.make_primary! if primary
    enrollment
  end

  # Unenroll the student from a classroom
  #
  # @param classroom [Classroom] the classroom to unenroll from
  # @param unenrolled_at [DateTime] when the student was unenrolled (defaults to now)
  # @return [void]
  def unenroll_from!(classroom, unenrolled_at: Time.current)
    current_enrollments.for_classroom(classroom).each do |enrollment|
      enrollment.unenroll!(at: unenrolled_at)
    end
  end

  private

  def set_default_email
    self.email = nil if email.blank?
  end

  def ensure_portfolio
    create_portfolio! if portfolio.blank?
  end

  def create_initial_enrollment
    # Create initial enrollment based on classroom_id
    # Set as primary since it's the first enrollment
    enroll_in!(classroom, enrolled_at: created_at, primary: true)
  end
end
