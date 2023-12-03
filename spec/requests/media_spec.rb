require "rails_helper"

RSpec.describe "Media", type: :request do
  describe "#search_by" do
    before do
      Medium.destroy_all

      @medium1 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Nuesse", description: "Erstes Medium")
      @medium2 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Nuesse", description: "Zweites Medium")
      @medium3 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   sort: "Quiz", description: "Drittes Medium")
      @medium4 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   :with_tags, sort: "Nuesse", description: "Getagtes Medium")
      @medium5 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   :with_tags, sort: "Nuesse", description: "Anderes Medium")

      @lecture1 = FactoryBot.create(:lecture)
      @medium6 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   teachable: @lecture1, sort: "Nuesse",
                                   description: "Erstes Medium mit Lehrer")
      @lecture2 = FactoryBot.create(:lecture, teacher: @lecture1.teacher)
      @medium7 = FactoryBot.create(:medium, :with_teachable, :with_editors, :released,
                                   teachable: @lecture2, sort: "Nuesse",
                                   description: "Zweites Medium mit Lehrer")
      @medium8 = FactoryBot.create(:medium, :with_teachable, :with_editors,
                                   sort: "Nuesse", description: "Unveröffentlichtes Medium")

      sign_in FactoryBot.create(:confirmed_user)
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

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).not_to include("Unveröffentlichtes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(Medium.where(released: "all").size)
    end

    it "can search for media by title" do
      @params[:search][:fulltext] = "Erstes"
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Erstes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it "can search for media by sort" do
      @params[:search][:all_types] = 0
      @params[:search][:types] = ["Quiz"]
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Drittes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it "can search for media by tag" do
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = @medium4.tags.pluck(:id)
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Getagtes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it 'can do combined search with tagoperator "or" and description' do
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = @medium4.tags.pluck(:id)
      @params[:search][:fulltext] = "Medium"
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      hits = parse_media_search(response)
      expect(hits).to eq(Medium.where(released: "all").size)
    end

    it 'can do search with tagoperator "and" and description' do
      @params[:search][:tag_operator] = "and"
      @params[:search][:all_tags] = 0
      @params[:search][:tag_ids] = @medium4.tags.pluck(:id)
      @params[:search][:fulltext] = "Medium"
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Getagtes Medium")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it 'can search for all media with tags by using tagoperator "and"' do
      @params[:search][:tag_operator] = "and"
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it "can search by teacher" do
      @params[:search][:all_teachers] = 0
      @params[:search][:teacher_ids] = [@lecture1.teacher.id]
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      hits = parse_media_search(response)
      expect(hits).to eq(2)
    end

    it "can search for media of subscribed lectures" do
      @params[:search][:lecture_option] = 1
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Erstes Medium mit Lehrer")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end

    it "can search for media of custom lecture" do
      @params[:search][:lecture_option] = 2
      @params[:search][:media_lectures] = [@lecture2.id]
      get media_search_path, params: @params

      expect(response.body).not_to include("The search has not returned any hits")
      expect(response.body).to include("Zweites Medium mit Lehrer")
      hits = parse_media_search(response)
      expect(hits).to eq(1)
    end
  end
end
