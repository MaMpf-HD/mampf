require "rails_helper"

RSpec.describe(Search::SearchOrderer) do
  let(:initial_scope) { instance_spy(ActiveRecord::Relation, "InitialScope") }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:params) { {} }

  subject(:ordered_scope) do
    described_class.call(
      scope: initial_scope,
      model_class: model_class,
      params: params
    )
  end

  describe "#call" do
    context "when performing a full-text search" do
      let(:params) { { fulltext: "search term" } }

      it "returns the original scope without modification" do
        expect(ordered_scope).to eq(initial_scope)
        expect(initial_scope).not_to have_received(:order)
      end
    end

    context "when the model is not orderable" do
      context "because it does not respond to default_search_order" do
        let(:unorderable_model) { Class.new }

        it "returns the original scope" do
          result = described_class.call(scope: initial_scope, model_class: unorderable_model,
                                        params: params)
          expect(result).to eq(initial_scope)
        end
      end

      context "because default_search_order is blank" do
        before { allow(model_class).to receive(:default_search_order).and_return("") }

        it "returns the original scope" do
          expect(ordered_scope).to eq(initial_scope)
        end
      end
    end

    context "when applying the default order" do
      let(:order_expression) { "title DESC, created_at ASC" }
      let(:select_expression) { Arel.sql("title, created_at") }

      before do
        # Stub the model to be orderable. This includes the check that fails.
        allow(model_class).to receive(:respond_to?).with(:default_search_order).and_return(true)
        allow(model_class).to receive(:default_search_order).and_return(order_expression)
        allow(model_class).to receive(:arel_table).and_return(Course.arel_table)

        # Stub the chain of calls on the scope
        allow(initial_scope).to receive(:select)
          .and_return(instance_spy(ActiveRecord::Relation, "SelectedScope"))
        allow(initial_scope).to receive(:left_outer_joins)
          .and_return(instance_spy(ActiveRecord::Relation, "JoinedScope"))
      end

      context "and the model does not require extra joins" do
        before do
          # Ensure the model does not respond to the joins method
          allow(model_class).to receive(:respond_to?).with(:default_search_order_joins)
                                                     .and_return(false)
        end

        it "applies the select and order clauses to the original scope" do
          selected_scope = instance_spy(ActiveRecord::Relation)
          allow(initial_scope).to receive(:select).and_return(selected_scope)

          ordered_scope

          expect(initial_scope).to have_received(:select).with(Course.arel_table[Arel.star],
                                                               select_expression)
          expect(selected_scope).to have_received(:order).with(order_expression)
        end

        it "does not attempt to join" do
          ordered_scope
          expect(initial_scope).not_to have_received(:left_outer_joins)
        end
      end

      context "and the model requires extra joins" do
        let(:joins) { :editors }
        let(:joined_scope) { instance_spy(ActiveRecord::Relation, "JoinedScope") }
        let(:selected_scope) { instance_spy(ActiveRecord::Relation, "SelectedScope") }

        before do
          # Stub the model to require joins
          allow(model_class).to receive(:respond_to?).with(:default_search_order_joins)
                                                     .and_return(true)
          allow(model_class).to receive(:default_search_order_joins).and_return(joins)

          # Stub the chain of calls
          allow(initial_scope).to receive(:left_outer_joins).with(joins).and_return(joined_scope)
          allow(joined_scope).to receive(:select).and_return(selected_scope)
        end

        it "applies joins first, then select, then order" do
          ordered_scope

          expect(initial_scope).to have_received(:left_outer_joins).with(joins)
          expect(joined_scope).to have_received(:select).with(Course.arel_table[Arel.star],
                                                              select_expression)
          expect(selected_scope).to have_received(:order).with(order_expression)
        end

        it "returns the final ordered scope" do
          final_scope = double("FinalScope")
          allow(selected_scope).to receive(:order).and_return(final_scope)
          expect(ordered_scope).to eq(final_scope)
        end
      end
    end
  end
end
