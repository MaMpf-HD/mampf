# Talks Helper
module TalksHelper
  def talk_positions_for_select(talk)
    [[t('basics.at_the_beginning'), 0]] + talk.lecture.select_talks -
      [[talk.to_label, talk.position]]
  end

  def talk_card_color(talk, user)
    return 'bg-mdb-color-lighten-2' unless user.in?(talk.speakers)
    'bg-info'
  end

  def speaker_list(talk)
    return t('basics.tba') unless talk.speakers.present?
    talk.speakers.map(&:tutorial_name).join(', ')
  end

  def date_list(talk)
    return t('basics.tba') unless talk.dates.present?
    list = talk.dates.collect do |d|
      content_tag(:span, localize(d, format: :concise),
                  class: 'badge badge-light mr-2')
    end.join.html_safe
  end
end