require "rails_helper"

RSpec.describe(Search::Orderers::LectureMediaOrderer) do
  let(:initial_scope) { Medium.all }
  let(:model_class) { Medium }
  let(:search_params) { { lecture_id: lecture.id } }
  let(:lecture) { create(:lecture_with_toc) }

  subject(:ordered_scope) do
    described_class.call(
      scope: initial_scope,
      model_class: model_class,
      search_params: search_params
    )
  end

  context "when lecture is not found" do
    before do
      allow(Lecture).to receive(:find_by).and_return(nil)
      allow(model_class).to receive(:default_search_order).and_return("created_at DESC")
    end

    it "applies the default model order" do
      expect(ordered_scope.to_sql).to include("ORDER BY created_at DESC")
    end
  end

  context "when lecture is found" do
    let!(:imported_medium) { create(:valid_medium) }
    let!(:lecture_medium) { create(:valid_medium, teachable: lecture) }
    let!(:lesson) { create(:valid_lesson, lecture: lecture) }
    let!(:lesson_medium) { create(:lesson_medium, teachable: lesson) }

    before do
      # Stub the dependencies to isolate the orderer's logic
      allow(Lecture).to receive(:find_by).with(id: lecture.id).and_return(lecture)
      allow(lecture).to receive_message_chain(:imported_media,
                                              :pluck).and_return([imported_medium.id])
    end

    it "joins the required tables" do
      sql = ordered_scope.to_sql
      expect(sql).to include('LEFT OUTER JOIN "lessons" "_search_lessons_media"')
      expect(sql).to include('LEFT OUTER JOIN "talks" "_search_talks_media"')
    end

    it "selects all original columns plus the new sort columns" do
      # The SELECT clause should contain the original columns and the aliased CASE statements
      expect(ordered_scope.select_values.count).to be > 7

      # Check the first part of the select, which should be "media".*
      arel_star = ordered_scope.select_values.first
      expect(arel_star).to be_a(Arel::Attributes::Attribute)
      expect(arel_star.relation.name).to eq("media")
      expect(arel_star.name).to eq("*")

      # Check that the other select values are aliased expressions
      expect(ordered_scope.select_values.second).to be_a(Arel::Nodes::As)
      expect(ordered_scope.select_values.second.to_sql).to include("AS sort_group1")
    end

    context "with default lesson order (order_factor = 1)" do
      before do
        allow(lecture).to receive(:order_factor).and_return(1)
      end

      it "builds the correct multi-level ORDER BY clause" do
        sql = ordered_scope.to_sql
        # Check for the main sorting groups
        expect(sql).to match(
          /
            ORDER\ BY\s+
            CASE\ WHEN\ "media"\."id"\ IN\ \(#{imported_medium.id}\)\ THEN\ 2\ ELSE\ 1\ END\s+
            ASC
          /x
        )
        expect(sql).to match(
          /
            CASE\ "media"\."teachable_type"\s+
            WHEN\ 'Lecture'\ THEN\ 1\s+
            WHEN\ 'Lesson'\ THEN\ 2\s+
            WHEN\ 'Talk'\ THEN\ 3\s+
            WHEN\ 'Course'\ THEN\ 4\s+
            ELSE\ 5\ END\s+
            ASC
          /x
        )
        # Check for lesson-specific ordering
        expect(sql).to match(
          /
            CASE\ WHEN\ "media"\."teachable_type"\ =\ 'Lesson'\s+
            THEN\ "_search_lessons_media"\."date"\ END\s+
            ASC
          /x
        )
        expect(sql).to match(
          /
            CASE\ WHEN\ "media"\."teachable_type"\ =\ 'Lesson'\s+
            THEN\ "_search_lessons_media"\."id"\ END\s+
            ASC
          /x
        )
      end
    end

    context "with reversed lesson order (order_factor = -1)" do
      before do
        allow(lecture).to receive(:order_factor).and_return(-1)
      end

      it "reverses the sort direction for lesson date and id" do
        sql = ordered_scope.to_sql
        # Check that lesson-specific ordering is now DESC
        expect(sql).to match(
          /
            CASE\ WHEN\ "media"\."teachable_type"\ =\ 'Lesson'\s+
            THEN\ "_search_lessons_media"\."date"\ END\s+
            DESC
          /x
        )
        expect(sql).to match(
          /
            CASE\ WHEN\ "media"\."teachable_type"\ =\ 'Lesson'\s+
            THEN\ "_search_lessons_media"\."id"\ END\s+
            DESC
          /x
        )
      end
    end
  end
end
