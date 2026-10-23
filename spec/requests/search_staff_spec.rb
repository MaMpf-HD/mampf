require "rails_helper"

RSpec.describe("Staff search", type: :request) do
  it "is open to the teaching staff" do
    teacher = create(:confirmed_user)
    create(:lecture, teacher: teacher)
    sign_in teacher

    get search_staff_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="media-search-results"')
  end

  it "is closed to students" do
    sign_in create(:confirmed_user)

    get search_staff_path

    expect(response).to redirect_to(root_path)
  end
end
