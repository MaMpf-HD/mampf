require "rails_helper"

RSpec.describe("Tag search", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:bookmarked_lecture) { create(:lecture) }
  let(:other_lecture) { create(:lecture) }

  let!(:tag_in_bookmarked_lecture) do
    create(:tag, title: "Eigenraum Alpha").tap do |tag|
      section = create(:section, chapter: create(:chapter, lecture: bookmarked_lecture))
      create(:section_tag_join, tag: tag, section: section)
    end
  end

  let!(:tag_in_bookmarked_course) do
    create(:tag, title: "Eigenraum Beta").tap do |tag|
      create(:course_tag_join, tag: tag, course: bookmarked_lecture.course)
    end
  end

  let!(:tag_in_other_lecture) do
    create(:tag, title: "Eigenraum Gamma").tap do |tag|
      section = create(:section, chapter: create(:chapter, lecture: other_lecture))
      create(:section_tag_join, tag: tag, section: section)
    end
  end

  let!(:tag_in_no_lecture) { create(:tag, title: "Eigenraum Delta") }

  before do
    user.bookmark_lecture!(bookmarked_lecture)
    sign_in user
  end

  def search(term)
    get(search_index_path(search: term),
        headers: { "Turbo-Frame" => "tag-search-results" })
  end

  it "shows only the tags of bookmarked lectures and their courses" do
    user.update!(subscription_type: 3)

    search("Eigenraum")

    expect(response.body).to include("Eigenraum Alpha", "Eigenraum Beta")
    expect(response.body).not_to include("Eigenraum Gamma", "Eigenraum Delta")
    expect(response.body).to include("2 additional results")
  end

  it "shows the tags of all lectures for a user who follows all courses" do
    user.update!(subscription_type: 2)

    search("Eigenraum")

    expect(response.body).to include("Eigenraum Alpha", "Eigenraum Beta", "Eigenraum Gamma")
    expect(response.body).not_to include("Eigenraum Delta")
    expect(response.body).to include("1 additional results")
  end

  it "adds the tags of preceding courses for a user who follows those" do
    user.update!(subscription_type: 1)
    create(:course_self_join, course: bookmarked_lecture.course,
                              preceding_course: other_lecture.course)

    search("Eigenraum")

    expect(response.body).to include("Eigenraum Alpha", "Eigenraum Beta", "Eigenraum Gamma")
    expect(response.body).not_to include("Eigenraum Delta")
  end

  it "reports a search without hits" do
    search("Quaternion")

    expect(response.body).to include("has returned 0 results")
  end

  it "needs no more queries when there are more lectures" do
    user.update!(subscription_type: 2)
    queries_before = queries_of_repeated_search("Eigenraum")

    create_list(:lecture, 5)

    expect(queries_of_repeated_search("Eigenraum")).to eq(queries_before)
  end

  # Counts the queries of the second of two identical searches, so that
  # filling the caches does not count.
  def queries_of_repeated_search(term)
    search(term)
    queries = 0
    counter = ->(*) { queries += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      search(term)
    end
    queries
  end
end
