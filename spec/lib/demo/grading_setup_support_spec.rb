require "rails_helper"

RSpec.describe(Demo::GradingSetupSupport, type: :model) do
  # The seed build runs in one transaction, and a task point updates its
  # participation's total only in an after_commit callback, which waits for
  # that transaction to commit.
  it "grades the demo exam by its points inside the build's transaction" do
    exam = create(:exam, :with_date)
    create_list(:exam_roster_entry, 6, exam: exam)
    support = Object.new.extend(described_class)

    ActiveRecord::Base.transaction do
      [:create_demo_exam_tasks!, :create_demo_participations!, :record_demo_absences!,
       :seed_demo_exam_points!, :apply_demo_grade_scheme!].each do |step|
        support.send(step, exam)
      end
    end

    reviewed = exam.assessment.assessment_participations.reviewed.to_a
    applier = Assessment::GradeSchemeApplier.new(exam.assessment.reload.grade_scheme)
    expect(reviewed.map(&:points_total)).to all(be_present)
    expect(reviewed.map(&:grade_numeric))
      .to eq(reviewed.map { |row| applier.compute_grade_for(row) })
  end
end
