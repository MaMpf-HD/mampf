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

  def speaker_icon_class(talk)
    return 'fas fa-user' unless talk.speakers.count > 1
    'fas fa-users'
  end

  def speaker_icon(talk)
    content_tag(:i,
                '',
                class: "#{speaker_icon_class(talk)} me-2",
                data: { toggle: 'tooltip' },
                title: t('admin.talk.speakers')).html_safe
  end

  def speaker_list_with_icon(talk)
    (speaker_icon(talk) + speaker_list(talk)).html_safe
  end

  def date_list(talk)
    talk.dates.map { |d| I18n.l(d) }.join(', ')
  end

  def cospeaker_list(talk, user)
    (talk.speakers.to_a - [user]).map(&:tutorial_name).join(', ')
  end
end