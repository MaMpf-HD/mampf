# Lets the records office read every lecture of a term: its groups and how full
# they are, and the published grades, the exam admissions and each group's
# addresses as downloads. Nothing here changes a record.
class RecordsOfficeController < ApplicationController
  authorize_resource class: false
  before_action :set_lecture, only: [:grades, :admissions]

  def current_ability
    @current_ability ||= RecordsOfficeAbility.new(current_user)
  end

  def index
    @term = Term.from_dashboard_param(params[:term]) || Term.active || Term.chronological.last
    @term_options = Term.chronological.reverse.map { |term| [term.to_label, term.dashboard_param] }
    @overview = RecordsOffice::TermOverview.new(@term)
  end

  def grades
    send_csv(RecordsOffice::Export.grades(@lecture), :grades, @lecture.title)
  end

  def admissions
    send_csv(RecordsOffice::Export.admissions(@lecture), :admissions, @lecture.title)
  end

  def emails
    group = RecordsOffice::TermOverview::GROUP_TYPES.fetch(params[:group_type])
                                                    .find(params[:group_id])
    send_csv(RecordsOffice::Export.emails(group), :emails,
             "#{group.lecture.title} #{RecordsOffice::TermOverview.group_title(group)}")
  end

  private

    def set_lecture
      @lecture = Lecture.find(params[:lecture_id])
    end

    def send_csv(csv, kind, subject)
      filename = "#{I18n.t("records_office.files.#{kind}")} #{subject}".parameterize
      send_data(csv, type: "text/csv; charset=utf-8", filename: "#{filename}.csv")
    end
end
