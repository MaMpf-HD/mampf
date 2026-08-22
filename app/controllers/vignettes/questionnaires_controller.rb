module Vignettes
  class QuestionnairesController < ApplicationController
    TAKE_ACTIONS = [:take, :submit_answer, :finish, :consent, :decide_consent,
                    :codename].freeze

    before_action :set_questionnaire,
                  only: [:take, :preview, :submit_answer, :finish, :consent,
                         :decide_consent, :codename, :edit, :update,
                         :update_closing_text, :publish, :export_statistics,
                         :update_slide_position, :destroy, :duplicate,
                         :revoke_consent]
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :check_take_accessibility, only: TAKE_ACTIONS
    before_action :check_index_accessibility, only: [:index]
    before_action :check_edit_accessibility,
                  only: [:create, :edit, :update, :update_closing_text, :preview,
                         :destroy, :publish, :update_slide_position, :duplicate,
                         :export_statistics, :revoke_consent]
    before_action :check_empty, only: TAKE_ACTIONS + [:publish]
    before_action :check_editable, only: [:update]

    def index
      @editor = current_user.can_edit?(@lecture)
      @questionnaires = @lecture.vignettes_questionnaires.order(:title)
      @questionnaires = @questionnaires.where(published: true) unless @editor

      render template: "vignettes/questionnaires/index/index",
             layout: lecture_layout
    end

    def take
      return redirect_to(consent_questionnaire_path(@questionnaire)) if consent_pending?

      @slide = slide_at(params[:position])
      @tracked = tracked?
      @answer = @slide.answers.build
      @answer.build_slide_statistic if @tracked

      render template: "vignettes/questionnaires/take/take",
             layout: lecture_layout
    end

    def consent
      return redirect_to(take_questionnaire_path(@questionnaire)) unless consent_pending?

      render template: "vignettes/questionnaires/consent/consent",
             layout: lecture_layout
    end

    def decide_consent
      return redirect_to(take_questionnaire_path(@questionnaire)) unless consent_pending?

      case params[:consent]
      when "decline"
        decide!(false)
        redirect_to take_questionnaire_path(@questionnaire)
      when "new"
        decide!(start_run(Codename.generate!).id)
        redirect_to codename_questionnaire_path(@questionnaire)
      when "existing"
        claim_existing_codename
      else
        redirect_to consent_questionnaire_path(@questionnaire),
                    alert: t("vignettes.consent.undecided")
      end
    end

    def codename
      @codename = current_run&.codename
      return redirect_to(consent_questionnaire_path(@questionnaire)) unless @codename

      render template: "vignettes/questionnaires/consent/codename",
             layout: lecture_layout
    end

    def preview
      if @questionnaire.slides.empty?
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.no_slides")
        return
      end

      @preview = true
      @position = params[:position].presence&.to_i || 1

      if @position > @questionnaire.slides.maximum(:position) || @position < 1
        redirect_to edit_questionnaire_path(@questionnaire)
        return
      end

      @slide = @questionnaire.slides.find_by(position: @position)
      @answer = @slide.answers.build

      render :take, template: "vignettes/questionnaires/take/take",
                    layout: lecture_layout
    end

    # Only a tracked run ever posts. An untracked one advances by link, so its
    # answers never reach the server, not even the request log.
    def submit_answer
      return redirect_to(consent_questionnaire_path(@questionnaire)) if consent_pending?
      return redirect_to(take_questionnaire_path(@questionnaire)) unless tracked?

      # Set for the sake of the re-render below, which goes through the take
      # template and would otherwise offer the untracked controls.
      @tracked = true
      @slide = @questionnaire.slides.find(answer_params[:slide_id])

      return unless save_answer

      return redirect_to(finish_questionnaire_path(@questionnaire)) if @slide.last_position?

      redirect_to take_questionnaire_path(@questionnaire, position: @slide.position + 1)
    end

    def finish
      @codename = current_run&.codename

      render template: "vignettes/questionnaires/finish/finish",
             layout: lecture_layout
    end

    def publish
      published = @questionnaire.published
      if @questionnaire.update(published: !published, editable: false)
        message_key = published ? "vignettes.unpublished" : "vignettes.published"
        redirect_to edit_questionnaire_path(@questionnaire), notice: t(message_key)
      else
        message_key = published ? "vignettes.published" : "vignettes.not_published"
        redirect_to edit_questionnaire_path(@questionnaire), alert: t(message_key)
      end
    end

    def update_slide_position
      unless @questionnaire.editable
        render json: { error: t("vignettes.not_editable") }, status: :unprocessable_content
        return
      end
      old_position = params[:old_position].to_i + 1
      new_position = params[:new_position].to_i + 1

      @slide = @questionnaire.slides.find_by(position: old_position)

      if new_position < 1 || new_position > @questionnaire.slides.maximum(:position)
        render json: { error: "Invalid position" }, status: :unprocessable_content
        return
      end

      # rubocop:disable Rails/SkipsModelValidations
      ActiveRecord::Base.transaction do
        @slide.update!(position: -1)
        if new_position > old_position
          @questionnaire.slides.where("position > ? AND position <= ?", old_position, new_position)
                        .update_all("position = position - 1")
        else
          @questionnaire.slides.where("position < ? AND position >= ?", old_position, new_position)
                        .update_all("position = position + 1")
        end

        @slide.update!(position: new_position)
      end
      # rubocop:enable Rails/SkipsModelValidations

      render json: { success: true }
    rescue StandardError => e
      Rails.logger.error("Slide position update failed: #{e.message}")
      render json: { error: t("vignettes.slide_not_updated") }, status: :unprocessable_content
    end

    def export_statistics
      csv_data = @questionnaire.answer_data_csv
      send_data(csv_data, filename: "questionnaire-#{@questionnaire.id}-answers.csv")
    end

    def new
      @questionnaire = Questionnaire.new
    end

    def edit
      @slides = @questionnaire.slides.order(:position)

      render template: "vignettes/questionnaires/edit/edit", layout: lecture_layout
    end

    def create
      @questionnaire = Questionnaire.new(questionnaire_params)
      if @questionnaire.save
        @questionnaire.lecture.touch
        redirect_to edit_questionnaire_path(@questionnaire)
      else
        redirect_to lecture_questionnaires_path(@lecture),
                    alert: t("vignettes.questionnaire_not_created")
      end
    end

    def update
      if @questionnaire.update(data_collection_params)
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.consent.saved")
      else
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.consent.not_saved")
      end
    end

    # Consent has to be revocable, and the codename is the only handle anyone
    # has on the data: there is no user to look it up by.
    def revoke_consent
      pseudonym = Codename.normalize(params[:pseudonym])
      codename = Codename.find_by(pseudonym: pseudonym) if pseudonym
      runs = codename ? @questionnaire.user_answers.where(codename: codename) : []
      count = runs.size
      runs.each(&:destroy)
      codename.destroy if codename && codename.user_answers.reload.empty?

      redirect_to edit_questionnaire_path(@questionnaire),
                  notice: t("vignettes.consent.revoked", count: count)
    end

    def update_closing_text
      if @questionnaire.update(closing_text_params)
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.closing.saved")
      else
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.closing.not_saved")
      end
    end

    def destroy
      @lecture = @questionnaire.lecture
      if @questionnaire.destroy
        @lecture.touch
        redirect_to lecture_questionnaires_path(@lecture), notice: t("vignettes.deleted")
      else
        redirect_to lecture_questionnaires_path(@lecture), alert: t("vignettes.not_deleted")
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        new_title = params[:title].presence || "Copy of #{@questionnaire.title}"
        new_questionnaire = @questionnaire.dup
        new_questionnaire.title = new_title
        new_questionnaire.published = false
        new_questionnaire.editable = true
        new_questionnaire.consent_text = @questionnaire.consent_text
        new_questionnaire.save!

        # Update lecture cache to show the new questionnaire
        @questionnaire.lecture.touch

        # Used to map old info slides to new info slides
        info_slides_mapping = {}

        # Duplicate info slides
        @questionnaire.info_slides.each do |info_slide|
          new_info_slide = info_slide.dup
          new_info_slide.content = info_slide.content
          new_info_slide.questionnaire = new_questionnaire
          new_info_slide.save!

          info_slides_mapping[info_slide.id] = new_info_slide.id
        end

        # Duplicate slides
        @questionnaire.slides.order(:position).each do |slide|
          new_slide = slide.dup
          new_slide.content = slide.content
          new_slide.questionnaire = new_questionnaire
          new_slide.save!

          slide.info_slides.each do |info_slide|
            new_info_slide_id = info_slides_mapping[info_slide.id]
            new_slide.info_slides << new_questionnaire.info_slides.find(new_info_slide_id)
          end

          new_question = slide.question.dup
          new_question.slide = new_slide
          new_question.save!

          next unless slide.question.type == "Vignettes::MultipleChoiceQuestion"

          slide.question.options.each do |option|
            new_option = option.dup
            new_option.question = new_question
            new_option.save!
          end
        end

        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    notice: t("vignettes.duplicated")
      end
    rescue StandardError => e
      Rails.logger.error("Failed to duplicate questionnaire: #{e.message}")
      redirect_to edit_questionnaire_path(@questionnaire),
                  alert: t("vignettes.not_duplicated")
    end

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find_by(id: params[:id])

        if @questionnaire
          @lecture = @questionnaire.lecture
          return
        end

        redirect_to :root, alert: t("vignettes.not_found")
      end

      # Vignettes are lecture content, so they sit next to the lecture sidebar
      # like media or the general information do.
      def lecture_layout
        turbo_frame_request? ? "turbo_frame" : "application"
      end

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])

        return if @lecture

        redirect_to :root, alert: t("vignettes.no_lecture")
      end

      # Vignettes are part of the lecture's content: whoever gets to see the
      # lecture gets to see them, once the lecture says it has any. Editors keep
      # their way in either way, so switching the checkbox off cannot strand
      # what they have already written.
      def content_accessible?
        return true if current_user.can_edit?(@lecture)

        @lecture.vignettes? && @lecture.in?(current_user.lectures)
      end

      def check_index_accessibility
        return if content_accessible?

        redirect_to lecture_home_path(@lecture), alert: t("vignettes.not_accessible")
      end

      def check_take_accessibility
        return if @questionnaire.published && content_accessible?

        redirect_to lecture_home_path(@lecture), alert: t("vignettes.not_accessible")
      end

      # @lecture is the questionnaire's lecture, or, for #create where there is
      # no questionnaire yet, the one it is about to be created in.
      def check_edit_accessibility
        return if current_user.can_edit?(@lecture)

        redirect_to lecture_home_path(@lecture), alert: t("vignettes.not_accessible")
      end

      # What students agreed to is frozen with the rest of the vignette. The way
      # to change it is to duplicate, which unlocks the copy.
      def check_editable
        return if @questionnaire.editable

        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.not_editable")
      end

      def check_empty
        return unless @questionnaire.slides.empty?

        target = if current_user.can_edit?(@lecture)
          edit_questionnaire_path(@questionnaire)
        else
          lecture_questionnaires_path(@lecture)
        end
        redirect_to target, alert: t("vignettes.no_slides")
      end

      def questionnaire_params
        params.permit(:title, :lecture_id)
      end

      def data_collection_params
        params.expect(vignettes_questionnaire: [:data_collection, :consent_text])
      end

      def closing_text_params
        params.expect(vignettes_questionnaire: [:closing_text])
      end

      def answer_params
        params
          .expect(vignettes_answer: [:slide_id, :text, :likert_scale_value,
                                     { option_ids: [],
                                       slide_statistic_attributes:
                                     [:time_on_slide, :total_time_on_slide,
                                      :time_on_info_slides, :info_slides_access_count,
                                      :info_slides_first_access_time] }])
      end

      # The position comes from the browser's memory, so it may well be stale
      # or made up; anything we cannot place falls back to the first slide.
      def slide_at(position)
        slides = @questionnaire.slides.order(:position)
        slides.find_by(position: position.to_i) || slides.first
      end

      # The consent decision lives in the session and nowhere else. A tracked
      # run is identified by its user answer, which hangs off a codename that
      # carries no user id, so the database never learns who answered.

      def decisions
        session[:vignettes_consent] ||= {}
      end

      def decision
        decisions[@questionnaire.id.to_s]
      end

      def decide!(value)
        decisions[@questionnaire.id.to_s] = value
      end

      def consent_pending?
        @questionnaire.collecting? && decision.nil?
      end

      # Asks the questionnaire again rather than trusting the session: a
      # consent text emptied mid-session must stop the collection at once.
      def tracked?
        @questionnaire.collecting? && current_run.present?
      end

      def current_run
        return @current_run if defined?(@current_run)

        @current_run =
          if decision.is_a?(Integer)
            UserAnswer.includes(:codename)
                      .find_by(id: decision, vignettes_questionnaire_id: @questionnaire.id)
          end
      end

      def start_run(codename)
        UserAnswer.create!(codename: codename, questionnaire: @questionnaire)
      end

      def claim_existing_codename
        codename = Codename.claim(params[:pseudonym])
        unless codename
          redirect_to consent_questionnaire_path(@questionnaire),
                      alert: t("vignettes.consent.malformed_codename")
          return
        end

        decide!(start_run(codename).id)
        redirect_to take_questionnaire_path(@questionnaire)
      end

      # Returns false when the answer could not be saved and a response has
      # already been rendered.
      def save_answer
        @answer = @slide.answers.build
        @answer.question = @slide.question
        @answer.type = @slide.question.type.gsub("Question", "Answer")
        @answer.user_answer = current_run
        @answer.assign_attributes(answer_params.except(:slide_id))

        return true if @answer.save

        Rails.logger.debug { "Answer save failed: #{@answer.errors.full_messages.join(", ")}" }
        render :take, template: "vignettes/questionnaires/take/take",
                      layout: lecture_layout,
                      status: :unprocessable_content
        false
      end
  end
end
