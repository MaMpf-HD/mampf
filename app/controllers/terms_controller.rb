# TermsController
class TermsController < ApplicationController
  before_action :set_term, only: [:destroy, :edit, :update, :cancel]
  authorize_resource

  def index
    @terms = Term.order(:year).reverse_order.page params[:page]
  end

  def destroy
    @term.destroy
    redirect_to terms_path
  end

  def edit
  end

  def update
    @term.update(term_params)
    @errors = @term.errors[:season].join(', ') unless @term.valid?
  end

  def cancel
  end

  private

  def set_term
    @id = params[:id]
    @term = Term.find_by_id(@id)
    return if @term.present?
    redirect_to terms_path, alert: 'Ein Semester mit der angeforderten id '\
                                   'existiert nicht.'
  end

  def term_params
    params.require(:term).permit(:year, :season)
  end

end
