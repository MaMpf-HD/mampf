require "rails_helper"

RSpec.describe(ProgramDistribution) do
  let(:math) { create(:subject, name: "Mathematics") }
  let(:bachelor) { create(:program, subject: math, name: "B.Sc. 100%", degree: :bsc100) }
  let(:master) { create(:program, subject: math, name: "M.Sc.", degree: :msc) }

  def student(program: nil, answered: program.present?)
    create(:confirmed_user, program: program,
                            personal_data_confirmed_at: (Time.current if answered))
  end

  let!(:people) do
    [student(program: bachelor), student(program: bachelor), student(program: master),
     student(answered: true), student]
  end

  let(:distribution) { described_class.new(User.where(id: people.map(&:id))) }

  it "counts the programs by size and then who picked none or has not answered" do
    expect(distribution.rows.map { |row| [row.key, row.people] })
      .to eq([[bachelor.id, 2], [master.id, 1], [:other, 1], [:unanswered, 1]])
    expect(distribution.total).to eq(5)
  end

  it "leaves out a bucket nobody is in" do
    answered = described_class.new(User.where(id: people.first(4).map(&:id)))

    expect(answered.rows.map(&:key)).not_to include(:unanswered)
  end

  it "groups the programs by subject, the larger subject first" do
    physics = create(:subject, name: "Physics")
    student(program: create(:program, subject: physics, name: "B.Sc. 100%", degree: :bsc100))
    everybody = described_class.new(User.where(id: User.select(:id)))

    expect(everybody.subjects.map { |row| [row.subject.name, row.people] })
      .to eq([["Mathematics", 3], ["Physics", 1]])
    expect(everybody.subjects.first.rows.map(&:key)).to eq([bachelor.id, master.id])
  end

  # The dean's office reads every student's program once per term and counts
  # each course from that.
  it "counts the same from pairs read beforehand" do
    pairs = User.where(id: people.map(&:id))
                .pluck(:program_id, :personal_data_confirmed_at)
                .map { |program_id, confirmed_at| [program_id, confirmed_at.present?] }
    read = described_class.from_pairs(pairs, programs: Program.all.index_by(&:id))

    expect(read.rows.map { |row| [row.key, row.people] })
      .to eq(distribution.rows.map { |row| [row.key, row.people] })
  end
end
