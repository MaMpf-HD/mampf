require "rails_helper"

RSpec.describe(StaffPostItComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  def render_note(user)
    render_inline(described_class.new(user: user))
  end

  def items(user)
    render_note(user).css(".staff-post-it__item").map { |item| item.text.squish }
  end

  it "is not pinned for a student" do
    expect(render_note(create(:confirmed_user)).text).to be_blank
  end

  it "offers a teacher without courses only the search" do
    teacher = create(:confirmed_user)
    create(:lecture, teacher: teacher)

    expect(items(teacher)).to eq(["Find media and tags"])
  end

  it "offers a course editor a new lecture and the courses they edit" do
    editor = create(:confirmed_user)
    course = create(:course, title: "Algebra")
    course.editors << editor

    rendered = render_note(editor)

    expect(items(editor)).to eq(["New lecture", "My courses", "Find media and tags"])
    expect(rendered.css("#staff-courses-modal li").map { |li| li.text.squish })
      .to eq(["Algebra Edit"])
  end
end
