require "rails_helper"

RSpec.describe(UserTextHelper, type: :helper) do
  def parsed(html)
    Nokogiri::HTML5.fragment(html)
  end

  shared_examples "a text with links" do |format|
    it "keeps a link to a web page or a mail address" do
      text = '<a href="https://example.com/page">page</a> ' \
             '<a href="http://example.com">site</a> ' \
             '<a href="mailto:tutor@example.com">mail</a>'

      links = parsed(helper.public_send(format, text)).css("a")

      expect(links.pluck("href"))
        .to eq(["https://example.com/page", "http://example.com",
                "mailto:tutor@example.com"])
    end

    it "shows a link with any other address as its text" do
      text = '<a href="/lectures/1">lecture</a> ' \
             '<a href="ftp://example.com/notes">notes</a>'

      shown = parsed(helper.public_send(format, text))

      expect(shown.css("[href]")).to be_empty
      expect(shown.text).to include("lecture", "notes")
    end

    it "keeps nothing but the address on a link" do
      text = '<a href="https://example.com" class="big" name="top" ' \
             'title="Example" target="_blank">page</a>'

      link = parsed(helper.public_send(format, text)).at_css("a")

      expect(link.keys).to eq(["href"])
      expect(link.text).to eq("page")
    end

    it "keeps an address on links only" do
      text = '<strong href="https://example.com">word</strong>'

      expect(helper.public_send(format, text)).to eq("<strong>word</strong>")
    end
  end

  describe "#format_comment_body" do
    it_behaves_like "a text with links", :format_comment_body

    it "keeps the formatting of the comment preview" do
      text = "A <b>bold</b> and a <strong>strong</strong> word, <i>italic</i> " \
             "and <em>emphasis</em>, then <code>x = 1</code> and a<br>line break."

      expect(helper.format_comment_body(text)).to eq("<p>#{text}</p>")
    end

    it "keeps paragraphs and preformatted text" do
      shown = parsed(helper.format_comment_body("<p>first</p><pre>a  b</pre>"))

      expect(shown.css("p").map(&:text)).to eq(["first"])
      expect(shown.at_css("pre").text).to eq("a  b")
    end

    it "puts each line into a paragraph of its own" do
      shown = parsed(helper.format_comment_body("first\n\nsecond"))

      expect(shown.css("p").map(&:text)).to eq(["first", "second"])
    end

    it "drops class and name and keeps the text" do
      text = '<b class="big" name="title">x</b> and <p class="big">more</p>'

      shown = parsed(helper.format_comment_body(text))

      expect(shown.css("[class], [name]")).to be_empty
      expect(shown.at_css("b").text).to eq("x")
      expect(shown.text).to include("and", "more")
    end

    it "drops images and all other tags and keeps their text" do
      text = 'before <img src="x.png" alt="figure"> after ' \
             '<span class="big">span</span> <h1>heading</h1> ' \
             "<ul><li>item</li></ul> <blockquote>quote</blockquote>"

      shown = parsed(helper.format_comment_body(text))

      expect(shown.css("img, span, h1, ul, li, blockquote")).to be_empty
      expect(shown.text)
        .to include("before", "after", "span", "heading", "item", "quote")
    end
  end

  describe "#format_talk_description" do
    it_behaves_like "a text with links", :format_talk_description

    it "keeps everything the editor writes" do
      text = "<h1>Outline</h1>" \
             "<div><strong>bold</strong>, <em>italic</em>, <del>struck</del>" \
             "<br>next line</div>" \
             "<blockquote>quote</blockquote><pre>x = 1</pre>" \
             "<ul><li>item<ul><li>nested item</li></ul></li></ul>" \
             "<ol><li>first</li></ol>" \
             '<div><a href="https://example.com">page</a></div>'

      expect(helper.format_talk_description(text)).to eq(text)
    end

    it "drops class and name and keeps the text" do
      text = '<div class="big" name="intro">x <strong class="big">y</strong>' \
             "</div>"

      expect(helper.format_talk_description(text))
        .to eq("<div>x <strong>y</strong></div>")
    end

    it "drops images and all other tags and keeps their text" do
      text = '<div>before <img src="x.png"> after</div>' \
             '<figure class="attachment"><img src="x.png">' \
             "<figcaption>caption</figcaption></figure>" \
             '<div><span class="big">span</span> <h2>heading</h2></div>'

      shown = parsed(helper.format_talk_description(text))

      expect(shown.css("img, figure, figcaption, span, h2")).to be_empty
      expect(shown.text)
        .to include("before", "after", "caption", "span", "heading")
    end
  end
end
