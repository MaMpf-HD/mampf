require "rails_helper"

RSpec.describe(Commontator::SubscriptionsMailer, type: :mailer) do
  describe "comment_created" do
    let(:comment) do
      Commontator::Comment.create!(
        thread: create(:lecture_medium).commontator_thread,
        creator: create(:confirmed_user),
        body: 'A <b class="big">bold</b> word and <img src="x.png"> more'
      )
    end

    it "shows the comment with the formatting of a comment" do
      mail = described_class.comment_created(comment, [create(:confirmed_user)])

      shown = Nokogiri::HTML5.fragment(mail.body.decoded)
      expect(shown.css("p").map(&:inner_html))
        .to include("A <b>bold</b> word and  more")
      expect(shown.css("img, [class]")).to be_empty
    end
  end
end
