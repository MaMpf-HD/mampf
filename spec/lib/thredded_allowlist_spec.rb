require "rails_helper"

RSpec.describe("Allowlist for forum posts") do
  def format_post(post, **)
    Thredded::ContentFormatter.new(nil, **).format_content(post)
  end

  # Rebuilds the allowlist as it is before config/initializers/thredded.rb
  # narrows it: thredded-markdown_katex adds all it allows once more, and the
  # transformers that the initializer appends are left out.
  def original_allowlist
    narrowed = Thredded::ContentFormatter.allowlist
    initializer = Rails.root.join("config/initializers/thredded.rb").to_s
    Thredded::ContentFormatter.allowlist = narrowed.deep_dup
    Thredded::MarkdownKatex.send(:configure_allowlist!)
    Thredded::ContentFormatter.allowlist.tap do |original|
      original[:transformers].reject! do |transformer|
        transformer.source_location.first == initializer
      end
    end
  ensure
    Thredded::ContentFormatter.allowlist = narrowed
  end

  describe "formulas" do
    {
      "an inline formula" =>
        ['Let $$e^{\pi i} + 1 = 0$$ hold.', 'class="katex"'],
      "an inline integral" =>
        ['The integral $$\int_0^1 f(x)\,dx$$ exists.', "position:relative"],
      "a display formula" =>
        ['$$\sum_{i=1}^n i = \frac{n(n+1)}{2}$$', "katex-display"],
      "a root" =>
        ['$$\sqrt[3]{x^2 + y^2}$$', "<path"],
      "an overline and a wide hat" =>
        ['$$\overline{a + b} + \widehat{abc}$$', "<svg"],
      "an arrow stretched over its label" =>
        ['$$A \xrightarrow{f \circ g} B$$', "<svg"],
      "a struck-out term" =>
        ['$$\cancel{x} + y$$', "<line"]
    }.each do |name, (post, part)|
      it "renders #{name} as the original allowlist does" do
        html = format_post(post)

        expect(html).to include(part)
        expect(html).to eq(format_post(post, allowlist: original_allowlist))
      end
    end
  end

  describe "link targets" do
    it "keeps the target of a Markdown link" do
      expect(format_post("[text](https://example.org)"))
        .to include('<a href="https://example.org"')
    end

    it "keeps the `href` of an SVG link, whose protocol is checked" do
      post = '<svg><a href="https://example.org"><text>text</text></a></svg>'

      expect(format_post(post)).to include('<a href="https://example.org"')
    end

    {
      "`xlink:href` from an SVG link" => [
        '<svg><a href="https://example.org" ' \
        'xlink:href="https://example.org/other"><text>text</text></a></svg>',
        [" xlink:href="]
      ],
      "`href` from MathML elements" => [
        '<math href="https://example.org"><mrow href="https://example.org">' \
        '<mtext href="https://example.org">text</mtext></mrow></math>',
        [" href="]
      ],
      "the base for relative link targets from an SVG link" => [
        '<svg><a href="other" xml:base="https://example.org/">' \
        "<text>text</text></a></svg>",
        [" xml:base="]
      ],
      "the values that an SVG animation writes" => [
        '<svg><a href="https://example.org"><animate attributeName="href" ' \
        'from="https://example.org/a" to="https://example.org/b" ' \
        'by="https://example.org/c" values="https://example.org/d">' \
        "</animate><text>text</text></a></svg>",
        [" from=", " to=", " by=", " values="]
      ]
    }.each do |name, (post, attributes)|
      it "drops #{name}, which the original allowlist lets through" do
        expect(format_post(post, allowlist: original_allowlist))
          .to include(*attributes)
        expect(format_post(post)).not_to include(*attributes)
      end
    end
  end

  describe "positioning" do
    it "keeps a relative position" do
      post = '<span style="position:relative;top:1em">text</span>'

      expect(format_post(post)).to include('style="position:relative;top:1em"')
    end

    ["absolute", "fixed", "sticky"].each do |position|
      it "drops the position `#{position}` and keeps the rest of the style" do
        post = %(<span style="position:#{position};top:1em">text</span>)

        expect(format_post(post, allowlist: original_allowlist))
          .to include("position:#{position}")
        expect(format_post(post)).to include('style="top:1em"')
      end
    end
  end
end
