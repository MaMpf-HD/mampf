# Talks Helper
module TalksHelper
  def talk_positions_for_select(talk)
    [[t("basics.at_the_beginning"), 0]] + talk.lecture.select_talks -
      [[talk.to_label, talk.position]]
  end

  def talk_card_color(talk, user)
    return "bg-mdb-color-lighten-2" unless user.in?(talk.speakers)

    "bg-info"
  end

  def speaker_list(talk)
    return t("basics.tba") if talk.speakers.blank?

    talk.speakers.map(&:tutorial_name).join(", ")
  end

  def speaker_icon_class(talk)
    return "bi bi-person-fill" unless talk.speakers.many?

    "bi bi-people-fill"
  end

  def speaker_icon(talk)
    content_tag(:i,
                "",
                class: "#{speaker_icon_class(talk)} me-2",
                data: { toggle: "tooltip" },
                title: t("admin.talk.speakers")).html_safe
  end

  def speaker_list_with_icon(talk)
    speaker_icon(talk) + speaker_list(talk)
  end

  def date_list(talk)
    talk.dates.map { |d| I18n.l(d) }.join(", ")
  end

  def cospeaker_list(talk, user)
    (talk.speakers.to_a - [user]).map(&:tutorial_name).join(", ")
  end

  def speakers_preselection(talk)
    options_for_select(talk.lecture.eligible_as_speakers.map do |s|
                         [s.tutorial_info, s.id]
                       end, talk.speaker_ids)
  end

  def speaker_select(form, talk, with_preselection)
    label = form.label(:speaker_ids, t("admin.talk.speakers"), class: "form-label")
    help_desk = helpdesk(t("admin.talk.info.speakers"), false)

    select = if current_user.admin?
      preselection = with_preselection ? speakers_preselection(talk) : [[]]
      form.select(:speaker_ids, preselection, {}, {
                    class: "selectize",
                    multiple: true,
                    data: {
                      ajax: true,
                      filled: false,
                      model: "user",
                      placeholder: t("basics.enter_two_letters"),
                      no_results: t("basics.no_results"),
                      modal: true,
                      cy: "speaker-select"
                    }
                  })
    else
      seminar_edit_people_link = "#{edit_lecture_path(talk.lecture)}#people"

      form.select(:speaker_ids, speakers_preselection(talk), {},
                  class: "selectize",
                  multiple: true,
                  data: {
                    cy: "speaker-select",
                    no_results: t("basics.no_results_speaker", link: seminar_edit_people_link)
                  })
    end

    label + help_desk + select
  end
end
