require "rails_helper"

RSpec.describe(Search::Orderers::LectureMediaOrderer) do
  let(:initial_scope) { Medium.all }
  let(:model_class) { Medium }
  let(:search_params) { { id: lecture.id } }

  subject(:ordered_scope) do
    described_class.call(
      scope: initial_scope,
      model_class: model_class,
      search_params: search_params
    )
  end

  context "when lecture is not found" do
    let(:lecture) { double(id: -1) } # A dummy object for the search_params
    before do
      allow(Lecture).to receive(:find_by).and_return(nil)
      allow(model_class).to receive(:default_search_order).and_return("created_at DESC")
    end

    it "applies the default model order" do
      expect(ordered_scope.to_sql).to include("ORDER BY created_at DESC")
    end
  end

  context "when lecture is found" do
    let!(:source_lecture) { create(:lecture, :released_for_all) }
    let!(:imported_medium) do
      create(:lecture_medium, teachable: source_lecture, released: "all")
    end
    let!(:lecture_medium) { create(:lecture_medium, teachable: lecture) }
    let!(:lesson) { create(:valid_lesson, lecture: lecture) }
    let!(:lesson_medium) { create(:lesson_medium, teachable: lesson) }

    let!(:import) do
      create(:import, teachable: lecture, medium: imported_medium)
    end

    context "when lecture is in an old (inactive) term" do
      let(:term) { create(:term, active: false) }
      let(:lecture) { create(:lecture_with_toc, term: term) }

      it "builds the correct multi-level ORDER BY clause with ASC lesson sorting" do
        sql = ordered_scope.to_sql

        # Using the robust regex from the original spec.
        # It correctly checks for the start of the ORDER BY clause.
        expect(sql).to match(
          /
            ORDER\ BY\s+
            CASE\ WHEN\ "media"\."id"\ IN\ \(#{imported_medium.id}\)\ THEN\ 2\ ELSE\ 1\ END\s+
            ASC
          /x
        )

        # Check for the other sorting groups
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

    context "when lecture is in the active term" do
      let(:term) { create(:term, active: true) }
      let(:lecture) { create(:lecture_with_toc, term: term) }

      it "reverses the sort direction for lesson date and id to DESC" do
        sql = ordered_scope.to_sql
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

    context "when lecture is term-independent" do
      let(:lecture) { create(:lecture_with_toc, :term_independent) }

      it "reverses the sort direction for lesson date and id to DESC" do
        sql = ordered_scope.to_sql
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
