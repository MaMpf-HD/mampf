# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
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
