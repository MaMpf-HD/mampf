# Lets the staff of a lecture make somebody an editor by the exact address of
# their confirmed account, besides an editor voucher. They are removed like
# any editor, in the people form's editor select.
class LectureEditorsController < ApplicationController
  before_action :set_lecture

  def current_ability
    @current_ability ||= LectureAbility.new(current_user)
  end

  def create
    authorize! :add_editor, @lecture
    email = params[:email].to_s.strip
    user = User.confirmed.find_by(email: email.downcase)
    unless user
      return render_editors(email: email, error: t(".no_account"),
                            status: :unprocessable_content)
    end

    added = !user.in?(@lecture.editors + [@lecture.teacher])
    if added
      @lecture.update_editor_status!(user)
      LectureNotifier.notify_new_editor_by_mail(user, @lecture)
    end
    flash.now[:notice] = t(added ? ".added" : ".already", name: user.tutorial_name)
    render_editors
  end

  private

    def set_lecture
      @lecture = Lecture.find(params[:lecture_id])
    end

    def render_editors(email: nil, error: nil, status: :ok)
      streams = [
        turbo_stream.update("lecture_editors_select",
                            partial: "lectures/edit/editors_select",
                            locals: { lecture: @lecture.reload }),
        turbo_stream.replace("lecture-editor-by-email",
                             partial: "lectures/edit/editor_by_email",
                             locals: { lecture: @lecture, email: email, error: error })
      ]
      if flash.now[:notice]
        streams << turbo_stream.prepend("flash-messages", partial: "flash/message")
      end
      render turbo_stream: streams, status: status
    end
end
