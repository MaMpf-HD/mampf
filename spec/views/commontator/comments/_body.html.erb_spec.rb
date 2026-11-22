require "rails_helper"

RSpec.describe("commontator/comments/_body.html.erb", type: :view) do
  it "shows the comment with the formatting of a comment and nothing else" do
    comment = Commontator::Comment.new(
      body: 'A <b class="big" name="title">bold</b> word, a ' \
            '<a href="https://example.com">link</a> and <img src="x.png"> more'
    )

    render(partial: "commontator/comments/body", locals: { comment: comment })

    expect(Nokogiri::HTML5.fragment(rendered).at_css("p").inner_html)
      .to eq('A <b>bold</b> word, a <a href="https://example.com">link</a> ' \
             "and  more")
  end
end
