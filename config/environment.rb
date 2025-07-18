require_relative "application"

Rails.application.initialize! unless ENV["RAILS_GROUPS"] == "assets"
