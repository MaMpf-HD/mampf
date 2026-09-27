require "rails_helper"

RSpec.describe(LectureContentComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, :term_independent) }
  let(:rings) { create(:chapter, lecture: lecture, title: "Ringe") }
  let!(:ideals) { create(:section, chapter: rings, title: "Ringe und Ideale") }
  let!(:euclid) { create(:section, chapter: rings, title: "Euklidische Ringe") }

  around { |example| I18n.with_locale(:en) { example.run } }

  def lesson_on(date, *sections)
    Lesson.create!(lecture: lecture, date: date, sections: sections)
  end

  def render_for(user)
    render_inline(described_class.new(lecture: lecture.reload, user: user))
  end

  it "renders nothing for a lecture without sessions, chapters or news" do
    empty = create(:lecture, :released_for_all, :term_independent)

    expect(described_class.new(lecture: empty, user: user).render?).to be(false)
  end

  context "while sessions are recent" do
    it "shows the last session, its topics and where the lecture stands" do
      lesson_on(2.weeks.ago.to_date, ideals)
      last = lesson_on(3.days.ago.to_date, euclid)
      last.tags << create(:tag, title: "euklidischer Algorithmus")

      html = render_for(user)

      expect(html.text.squish).to include("Last lecture")
      expect(html.text.squish).to include("#{euclid.displayed_number} Euklidische Ringe")
      expect(html.text.squish).to include("euklidischer Algorithmus")
      expect(html.text.squish).to include("Where we are")
      expect(html.css("[role=img][aria-label='Section 2 of 2']")).to be_present
    end

    it "names the notes of the session by kind, and by name once there are several" do
      lesson = lesson_on(3.days.ago.to_date, ideals)
      create(:lesson_medium, :released, :with_manuscript, teachable: lesson,
                                                          description: "Skript 5")

      links = render_for(user).css(".lecture-home-content-media a").map { |a| a.text.squish }
      expect(links).to eq(["Notes"])

      create(:lesson_medium, :released, :with_manuscript, teachable: lesson,
                                                          description: "Beweisskizze")
      links = render_for(user).css(".lecture-home-content-media a").map { |a| a.text.squish }
      expect(links).to contain_exactly("Skript 5 · Notes", "Beweisskizze · Notes")
    end

    it "lists new media and how many more there are" do
      lesson = lesson_on(3.days.ago.to_date, ideals)
      media = Array.new(3) do |index|
        create(:lesson_medium, :released, teachable: lesson, description: "Blatt #{index}")
      end
      media.each { |medium| create(:notification, recipient: user, notifiable: medium) }

      html = render_for(user)

      expect(html.text.squish).to include("New for you")
      expect(html.css("a").pluck("href").grep(%r{\A/media/\d+\z}).size).to eq(2)
      expect(html.text.squish).to include("and 1 more")
    end

    it "leaves out the news of other people" do
      lesson = lesson_on(3.days.ago.to_date, ideals)
      medium = create(:lesson_medium, :released, teachable: lesson)
      create(:notification, recipient: create(:confirmed_user), notifiable: medium)

      html = render_for(user)

      expect(html.text.squish).not_to include("New for you")
    end
  end

  context "for a running lecture that keeps no sessions, only an outline" do
    it "shows its contents" do
      html = render_for(user)

      expect(html.text.squish).to include("Contents")
      expect(html.text.squish).to include("1 chapter")
      expect(html.text.squish).not_to include("Lectures over")
      expect(html.text.squish).not_to include("Last lecture")
    end

    it "still lists new media" do
      medium = create(:lecture_medium, :released, teachable: lecture)
      create(:notification, recipient: user, notifiable: medium)

      html = render_for(user)

      expect(html.text.squish).to include("New for you")
    end
  end

  context "once the sessions have stopped" do
    before do
      lesson_on(8.weeks.ago.to_date, ideals)
      lesson_on(6.weeks.ago.to_date, euclid)
    end

    it "gives an overview of the sessions and chapters" do
      html = render_for(user)

      expect(html.text.squish).to include("Lectures over")
      expect(html.text.squish).to include("2 lectures")
      summaries = html.css("summary").map { |summary| summary.text.squish }
      expect(summaries).to include("Ringe · 2 sections")
      expect(html.text.squish).to include("#{ideals.displayed_number} Ringe und Ideale")
      expect(html.text.squish).not_to include("Last lecture")
    end

    it "names only the chapter when its one section repeats the title" do
      intro = create(:chapter, lecture: lecture, title: "Einführung")
      create(:section, chapter: intro, title: "Einführung")

      html = render_for(user)

      expect(html.text.squish).to include("Einführung")
      expect(html.text.squish).not_to include("Einführung · 1 section")
    end

    it "offers the materials for revision with how many there are" do
      lesson = lecture.lessons.first
      2.times { create(:lesson_medium, :released, teachable: lesson) }

      html = render_for(user)

      expect(html.text.squish).to include("For review")
      expect(html.css("a").map { |a| a.text.strip }).to include("Lessons (2)")
    end
  end

  context "with a lecture of a past term" do
    let(:lecture) do
      create(:lecture, :released_for_all, term: create(:term, :winter, year: 2020))
    end

    it "shows it as an archive" do
      lesson_on(Date.new(2020, 11, 3), ideals)

      html = render_for(user)

      expect(html.text.squish).to include(lecture.term.to_label)
      expect(html.text.squish).to include("1 lecture")
      expect(html.text.squish).not_to include("Lectures over")
    end
  end
end
