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
    talk.dates.map { |d| I18n.l(d) }.join(', ')
  end

  def cospeaker_list(talk, user)
    (talk.speakers.to_a - [user]).map(&:tutorial_name).join(', ')
  end
end