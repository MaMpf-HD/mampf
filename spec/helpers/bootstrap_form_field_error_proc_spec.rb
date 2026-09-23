require "rails_helper"

RSpec.describe("bootstrap_form next to the app's field_error_proc") do
  let(:app_proc_file) { Rails.root.join("config/initializers/form_errors.rb").to_s }

  around do |example|
    app_proc = ActionView::Base.field_error_proc
    example.run
  ensure
    ActionView::Base.field_error_proc = app_proc
  end

  def render_bootstrap_form(entered, leave)
    ActionView::Base.empty.send(:with_bootstrap_form_field_error_proc) do
      entered << true
      leave.pop
    end
  end

  it "keeps the app's field_error_proc after two bootstrap forms render at once" do
    first_in = Queue.new
    second_in = Queue.new
    first_out = Queue.new
    second_out = Queue.new

    first = Thread.new { render_bootstrap_form(first_in, first_out) }
    first_in.pop
    second = Thread.new { render_bootstrap_form(second_in, second_out) }
    second_in.pop
    first_out << true
    first.join
    second_out << true
    second.join

    expect(ActionView::Base.field_error_proc.source_location.first).to eq(app_proc_file)
  end

  it "leaves the fields of a bootstrap form to bootstrap_form" do
    user = User.new
    user.errors.add(:email, :blank)

    html = ActionView::Base.empty.bootstrap_form_with(model: user, url: "/users") do |f|
      f.email_field(:email)
    end

    expect(html.scan("invalid-feedback").size).to eq(1)
  end

  it "still marks the fields of every other form" do
    user = User.new
    user.errors.add(:email, :blank)

    html = ActionView::Base.empty.form_with(model: user, url: "/users") do |f|
      f.email_field(:email)
    end

    expect(html).to include("is-invalid")
  end
end
