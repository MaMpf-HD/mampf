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
end