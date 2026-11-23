require "rails_helper"

RSpec.describe("commontator/comments/_form.html.erb", type: :view) do
  let(:thread) { create(:lecture_medium).commontator_thread }
  let(:comment) do
    Commontator::Comment.create!(
      thread: thread, creator: create(:confirmed_user),
      body: 'A <b class="big" name="title">bold</b> word, a ' \
            '<a href="https://example.com">link</a> and <img src="x.png"> more'
    )
  end

  it "previews the comment the way it is shown afterwards" do
    assign(:commontator_thread, thread)

    render(partial: "commontator/comments/form", locals: { comment: comment })

    preview = Nokogiri::HTML5.fragment(rendered)
                             .at_css("#commontator-comment-#{comment.id}-edit-body-preview")
    expect(preview.at_css("p").inner_html)
      .to eq('A <b>bold</b> word, a <a href="https://example.com">link</a> ' \
             "and  more")
  end
end
