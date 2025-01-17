FactoryBot.define do
  factory :vignettes_slide_statistic, class: 'Vignettes::SlideStatistic' do
    user { nil }
    slide { nil }
    time_on_slide { 1 }
    time_on_info_slide { 1 }
  end
end
