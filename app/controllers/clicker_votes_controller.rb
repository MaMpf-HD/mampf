# ClickerVotesController
class ClickerVotesController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    @vote = ClickerVote.new(vote_params)
    @clicker = @vote.clicker
    if cookies["clicker-#{@clicker.id}"] != @clicker.instance
      @vote.save
      cookies["clicker-#{@vote.clicker_id}"] = @clicker.instance if @vote.valid?
    end
    head :ok
  end

  private

  def vote_params
    params.require(:clicker_vote).permit(:clicker_id, :value)
  end
end
