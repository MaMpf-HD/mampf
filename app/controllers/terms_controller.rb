# TermsController
class TermsController < ApplicationController
  before_action :set_term, except: [:index, :new, :create, :cancel, :set_active]
  layout "administration"
  authorize_resource except: [:index, :new, :create, :cancel, :set_active]
  layout "administration"

  def current_ability
    @current_ability ||= TermAbility.new(current_user)
  end

  def index
    authorize! :index, Term.new
    @terms = Term.order(:year, :season).reverse_order.page(params[:page])
  end

  def new
    @term = Term.new
    authorize! :new, @term
  end

  def edit
  end

  def create
    @term = Term.new(term_params)
    authorize! :create, @term
    @term.save
    if @term.valid?
      redirect_to terms_path
      return
    end
    @errors = @term.errors[:season].join(", ")
    render :update
  end

  def update
    @term.update(term_params)
    @errors = @term.errors[:season].join(", ") unless @term.valid?
  end

  def destroy
    @term.destroy
    redirect_to terms_path
  end

  def cancel
    @id = params[:id]
    @term = Term.find_by(id: @id)
    authorize! :cancel, @term
    @new_action = params[:new] == "true"
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
      params.require(:term).permit(:year, :season)
    end

    def active_term_params
      params.permit(:active_term)
    end
end
