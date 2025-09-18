# GradeBook Earnings

Students earn money in their portfolios through attendance and grades in their classes. This document outlines how these grade book earnings are calculated and recorded in the system.

## Grade Book Structure
- Each classroom has a grade book for each quarter of the school year.
- At the end of each quarter, teachers and/or admins enter attendance and grades for each student in the classroom.
  - *Note*: This grade book is only used to calculate earnings. This system is not responsible for individual grade management or report cards.
- The following [entries](../app/models/grade_entry.rb) are supported for each student in the class for the grade book:
  - Number of days attended
  - Perfect Attendance (boolean)
  - Reading Grade
  - Math Grade

## Earnings Calculation
- Once grades have been entered, an admin can "finalize" the grade book for the quarter. This action will calculate earnings for each student based on their attendance and grades and create the corresponding transactions in their portfolios.
- The earnings are calculated as follows:
- Attendance:
  - $0.20 per day attended
  - $1.00 bonus for perfect attendance
- Grades:
  - Reading Grade in the A range: $3.00
  - Reading Grade in the B range: $2.00
  - Math Grade in the A range: $3.00
  - Math Grade in the B range: $2.00
- Grade Improvements
  - If a student's grade improves from the previous quarter, they receive an additional bonus:
    - Improvement in Reading Grade: $2.00
    - Improvement in Math Grade: $2.00
  - *Note* We currently are not looking at improvements across school years. So there are no improvement bonuses for the first quarter of a school year.

See the [DistributeEarnings](../app/services/distribute_earnings.rb) class for the implementation of this logic.
