class TermsController < ApplicationController
  before_action :set_term, except: [:index, :new, :create, :set_active]
  authorize_resource except: [:index, :new, :create, :set_active]
  layout "administration"

  def current_ability
    @current_ability ||= TermAbility.new(current_user)
  end

  def index
    authorize! :index, Term.new
    @pagy, @terms = pagy(Term.order(:year, :season).reverse_order)
  end

  def new
    @term = Term.new
    authorize! :new, @term
    render template: "terms/_form",
           locals: { term: @term },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def edit
    render template: "terms/_form",
           locals: { term: @term },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def create
    @term = Term.new(term_params)
    authorize! :create, @term
    if @term.save
      respond_to do |format|
        format.html { redirect_to terms_path }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("terms", @term),
            turbo_stream.update(Term.new, "")
          ]
        end
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @term.update(term_params)
      redirect_to terms_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @term.destroy
    respond_to do |format|
      format.html { redirect_to terms_path }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@term) }
    end
  end

  def set_active
    authorize! :set_active, Term.new
    new_active_term = Term.find_by(id: active_term_params[:active_term])
    old_active_term = Term.active
    if old_active_term && new_active_term && new_active_term != old_active_term
      old_active_term.update(active: false)
      new_active_term.update(active: true)
    elsif old_active_term.nil? && new_active_term
      new_active_term.update(active: true)
    end
    redirect_to :terms
  end

  private

    def set_term
      @id = params[:id]
      @term = Term.find_by(id: @id)
      return if @term

      redirect_to terms_path, alert: I18n.t("controllers.no_term")
    end

    def term_params
      params.expect(term: [:year, :season])
    end

    def active_term_params
      params.permit(:active_term)
    end
end
