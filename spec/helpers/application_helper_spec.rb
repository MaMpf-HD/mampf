require "rails_helper"

RSpec.describe(ApplicationHelper, type: :helper) do
  describe "#progress_bar" do
    it "renders a progress bar with correct percentage" do
      html = helper.progress_bar(50, 100)
      expect(html).to include('style="width: 50.0%"')
      expect(html).to include('aria-valuenow="50"')
      expect(html).to include("50%")
    end

    it "clamps percentage to 100" do
      html = helper.progress_bar(150, 100)
      expect(html).to include('style="width: 100%"')
    end

    it "handles zero max value" do
      html = helper.progress_bar(50, 0)
      expect(html).to include('style="width: 0%"')
    end

    it "applies utilization colors" do
      expect(helper.progress_bar(50, 100, classification: :utilization))
        .to include("bg-success")
      expect(helper.progress_bar(85, 100, classification: :utilization))
        .to include("bg-warning")
      expect(helper.progress_bar(100, 100, classification: :utilization))
        .to include("bg-danger")
    end

    it "applies custom classification colors" do
      expect(helper.progress_bar(50, 100, classification: :info))
        .to include("bg-info")
    end

    it "supports custom height and style" do
      html = helper.progress_bar(50, 100, height: "10px", style: "width: 50px")
      expect(html).to include('style="width: 50px; height: 10px"')
    end

    it "can hide label" do
      html = helper.progress_bar(50, 100, show_label: false)
      expect(html).not_to include("50%")
    end
  end

  describe "#utilization_color" do
    it "returns success for low usage" do
      expect(helper.send(:utilization_color, 40)).to eq("bg-success")
    end

    it "returns warning for medium usage" do
      expect(helper.send(:utilization_color, 85)).to eq("bg-warning")
    end

    it "returns danger for high usage" do
      expect(helper.send(:utilization_color, 110)).to eq("bg-danger")
    end
  end

  # NEEDS TO BE REFACTORED

  # describe '#full_title' do
  #   context 'if page_title is not given' do
  #     it 'returns MaMpf' do
  #       title = full_title
  #       expect(title).to eq 'MaMpf'
  #     end
  #   end
  #   context 'if page title is given' do
  #     it 'returns the correct full title' do
  #       page_title = [*('A'..'Z')].sample(8).join
  #       title = full_title(page_title)
  #       expect(title).to eq 'MaMpf | ' + page_title
  #     end
  #   end
  # end

  # describe '#split_list' do
  #   before do
  #     length = rand(50..150)
  #     @list = Array.new(length){ rand(1..9).to_s}
  #   end
  #   context 'if n is not given' do
  #     it 'splits the list into 4 pieces' do
  #       expect(split_list(@list).count).to eq(4)
  #     end
  #     it 'splits the list into pieces whose join is the original list' do
  #       expect(split_list(@list).flatten.reject(&:nil?)).to eq(@list)
  #     end
  #   end
  #   context 'if n is given' do
  #     before do
  #       @n = rand(2..10)
  #     end
  #     it 'splits the list into n pieces' do
  #       expect(split_list(@list,@n).count).to eq(@n)
  #     end
  #     it 'splits the list into pieces whose join is the original list' do
  #       expect(split_list(@list,@n).flatten.reject(&:nil?)).to eq(@list)
  #     end
  #   end
  # end
end
