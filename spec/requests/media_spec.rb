require "rails_helper"

NO_HITS_MSG = "The search has not returned any hits".freeze

def expect_no_results(response)
  expect(response.body).to include(NO_HITS_MSG)
end

def expect_all_results(response)
  expect(response.body).not_to include(NO_HITS_MSG)
  num_hits = parse_media_search(response)
  expect(num_hits).to eq(Medium.where(released: "all").size)
end

RSpec.describe("Media", type: :request) do
  describe "#search_by" do
    before do
      @medium1 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Exercise", description: "Erstes Medium")
      @medium2 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Exercise", description: "Zweites Medium")
      @medium3 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Quiz", description: "Drittes Medium")
      @medium4 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   :with_tags, sort: "Exercise", description: "Getagtes Medium")
      @medium5 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   :with_tags, sort: "Exercise", description: "Anderes Medium")

      @tag1 = FactoryBot.create(:tag, title: "mampf adventures")
      @tag2 = FactoryBot.create(:tag, title: "topology")
      @medium4.tags << @tag1
      @medium5.tags << @tag2

      @lecture1 = FactoryBot.create(:lecture)
      @medium6 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   teachable: @lecture1, sort: "Exercise",
                                   description: "Erstes Medium mit Lehrer")
      @lecture2 = FactoryBot.create(:lecture, teacher: @lecture1.teacher)
      @medium7 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   teachable: @lecture2, sort: "Exercise",
                                   description: "Zweites Medium mit Lehrer")
      @medium8 = FactoryBot.create(:medium, :with_teachable, :with_editors,
                                   sort: "Exercise", description: "Unveröffentlichtes Medium")

      sign_in FactoryBot.create(:confirmed_user_en)
      User.last.subscribe_lecture!(@lecture1)

      Medium.reindex

      @params = {
        search: {
          all_types: 1,
          all_tags: 1,
          tag_operator: "or",
          all_teachers: 1,
          lecture_option: 0,
          fulltext: "",
          per: 6,
          purpose: "media",
          results_as_list: false
        }
      }
    end

    it "can search for all (released) media" do
      get media_search_path, params: @params

      expect(response.body).not_to include("Unveröffentlichtes Medium")
      expect_all_results(response)
    end

    it "can search for media by title" do
      @params[:search][:fulltext] = "Erstes"
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Erstes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it "can search for media by sort" do
      @params[:search][:all_types] = 0
      @params[:search][:types] = ["Quiz"]
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Drittes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it "can search for media by tag" do
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = @medium4.tags.pluck(:id)
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Getagtes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it 'can do combined search with tagoperator "or" and description' do
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = [@medium4.tags.pluck(:id), @medium5.tags.pluck(:id)].flatten
      @params[:search][:fulltext] = "Medium"
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Getagtes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it 'can do search with tagoperator "and" and description' do
      @params[:search][:tag_operator] = "and"
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = [@tag1, @tag2].map(&:id)
      @params[:search][:fulltext] = "Medium"
      get media_search_path, params: @params

      expect_no_results(response)
    end

    it '"all tags" has higher precedence than any tagoperator (here "and")' do
      @params[:search][:all_tags] = 1
      @params[:search][:tag_operator] = "and"
      get media_search_path, params: @params

      expect_all_results(response)
    end

    it '"all tags" has higher precedence than any tagoperator (here "or")' do
      @params[:search][:all_tags] = 1
      @params[:search][:tag_operator] = "or"
      get media_search_path, params: @params

      expect_all_results(response)
    end

    it "can search by teacher" do
      @params[:search][:all_teachers] = 0
      @params[:search][:teacher_ids] = [@lecture1.teacher.id]
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it "can search for media of subscribed lectures" do
      @params[:search][:lecture_option] = 1
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Erstes Medium mit Lehrer")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it "can search for media of custom lecture" do
      @params[:search][:lecture_option] = 2
      @params[:search][:media_lectures] = [@lecture2.id]
      get media_search_path, params: @params

      expect(response.body).not_to include(NO_HITS_MSG)
      expect(response.body).to include("Zweites Medium mit Lehrer")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end
  end
end
