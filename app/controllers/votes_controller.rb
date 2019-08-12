# VotesController
class VotesController < ApplicationController
  skip_before_action :authenticate_user!


  def create
    @vote = Vote.new(vote_params)
    @clicker = @vote.clicker
    if cookies["clicker-#{@clicker.id}"] != @clicker.instance
      @vote.save
      if @vote.valid?
       cookies["clicker-#{@vote.clicker_id}"] = @clicker.instance
      end
      @errors = @vote.errors
    else
      @errors = 'voted already'
    end
  end

  private

  def vote_params
    params.require(:vote).permit(:clicker_id, :value)
  end
end
