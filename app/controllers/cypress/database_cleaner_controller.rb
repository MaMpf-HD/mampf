class Cypress::DatabaseCleanerController < Cypress::CypressController
  def create
    res = DatabaseCleaner.clean_with(:truncation)

    render json: res.to_json, status: :created
  end
end
