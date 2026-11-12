require "rails_helper"

RSpec.describe("Allowlist for forum posts") do
  def format_post(post, **)
    Thredded::ContentFormatter.new(nil, **).format_content(post)
  end

  # Rebuilds the allowlist as it is before config/initializers/thredded.rb
  # narrows it: thredded-markdown_katex adds all it allows once more.
  def original_allowlist
    narrowed = Thredded::ContentFormatter.allowlist
    Thredded::ContentFormatter.allowlist = narrowed.deep_dup
    Thredded::MarkdownKatex.send(:configure_allowlist!)
    Thredded::ContentFormatter.allowlist
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
        ['$$\cancel{x} + y$$', "<line"],
      "fractions and binomials" => [
        '$$\frac{1}{1 + \frac{a}{b}} + \dfrac{c}{d} + \tfrac{e}{f} + ' \
        '\binom{n}{k} + \cfrac{x}{y}$$',
        "frac-line"
      ],
      "a matrix and an array with rules" => [
        '$$\begin{pmatrix} a & b \\\\ c & d \end{pmatrix} ' \
        '\begin{array}{c|l:r} 1 & 2 & 3 \\\\ \hline 4 & 5 & 6 \\\\ ' \
        '\hdashline 7 & 8 & 9 \end{array}$$',
        "col-align-l"
      ],
      "cases with a tag" => [
        '$$\begin{cases} x & \text{if } x \geqslant 0 \\\\ ' \
        '-x & \text{otherwise} \end{cases} \tag{1}$$',
        'class="tag"'
      ],
      "numbered equations" => [
        '$$\begin{align} a &= b \\\\ c &= d \end{align}$$',
        "eqn-num"
      ],
      "sizing commands" => [
        '$${\tiny a {\normalsize b}} {\sixptsize a {\normalsize b}} ' \
        '{\scriptsize a {\normalsize b}} {\footnotesize a {\normalsize b}} ' \
        '{\small a {\normalsize b}} {\large a {\normalsize b}} ' \
        '{\Large a {\normalsize b}} {\LARGE a {\normalsize b}} ' \
        '{\huge a {\normalsize b}} {\Huge a {\normalsize b}}$$',
        "reset-size11 size6"
      ],
      "delimiters of several sizes" => [
        '$$\left( \frac{a}{b} \right) \big[ \Big\{ \bigg\langle \Bigg\vert ' \
        '\left\{ \begin{matrix} a \\\\ b \\\\ c \\\\ d \\\\ e \end{matrix} ' \
        '\right\rceil \left. x \right)$$',
        "delimsizing"
      ],
      "colours" => [
        '$$\color{blue} x + \textcolor{red}{y} + \colorbox{yellow}{z} + ' \
        '\fcolorbox{red}{white}{w}$$',
        "color:blue"
      ],
      "accents and braces" => [
        '$$\hat{a} + \tilde{b} + \vec{c} + \bar{d} + \dot{e} + \ddot{f} + ' \
        '\widehat{xyz} + \underline{g} + \overrightarrow{AB} + ' \
        '\underbrace{x + y}_{n} + \overbrace{u + v}^{m} + \utilde{h}$$',
        "accent-body"
      ],
      "arrows with labels above and below" => [
        '$$A \xleftrightarrow[g]{f} B \xrightleftharpoons{h} C$$',
        "x-arrow-pad"
      ],
      "text mode and fonts" => [
        '$$\text{if } x \textbf{ is } \textit{really } \texttt{small} ' \
        '\textsf{, } \textmd{then } \textup{so } \textrm{is } \mathrm{d}x, ' \
        '\mathbb{R}, \mathcal{L}, \mathfrak{g}, \mathsf{A}, \mathtt{B}, ' \
        '\mathscr{C}, \mathit{D}, \mathbf{E}, \mathsfit{F}, ' \
        '\boldsymbol{\alpha}, \text{\textcircled{a}}$$',
        "textbf"
      ],
      "letters typed as mathematical characters" => [
        '$$𝕬 + 𝗔 + 𝘈 + \text{𝔸 𝕬 𝗔 𝔄 𝘈 𝒜}$$',
        "textboldfrak"
      ],
      "operators with limits" => [
        '$$\sum_{i=1}^n a_i + \prod_{k} b_k + \lim_{x \to 0} f(x) + ' \
        '\int\limits_a^b g + \bigcup_{j} A_j + \operatorname*{argmax}_x h$$',
        "op-limits"
      ],
      "inline operators with limits" => [
        'With $$\sum_{i=1}^n a_i$$ and $$\max_x f(x)$$ in a line.',
        "small-op"
      ],
      "a line break in an inline formula" => [
        'Both $$a \\\\ b$$ in a line.',
        "newline"
      ],
      "spacing, overlaps and kinds of symbols" => [
        '$$a \, b \; c \quad d~e \nobreak f \allowbreak g + \llap{h} ' \
        '\rlap{i} \mathclap{j} \phantom{k} \smash{l} \mathrel{R} ' \
        '\mathbin{B} \mathopen{(} \mathclose{)} \mathpunct{,} \mathinner{I} ' \
        '\overset{a}{=} \vcenter{m} \raisebox{1pt}{n} \rule{1em}{1pt}$$',
        "mspace"
      ],
      "boxes and strokes" => [
        '$$\boxed{a} + \fbox{b} + \sout{c} + \bcancel{de} + \xcancel{f} + ' \
        '\angl{n} + \phase{g}$$',
        "boxpad"
      ],
      "a commutative diagram" => [
        '$$\begin{CD} A @>f>> B \\\\ @VgVV @VVhV \\\\ C @>>k> D \end{CD}$$',
        "cd-vert-arrow"
      ],
      "text in several scripts" => [
        '$$\text{Łódź Привет Հայերեն हिन्दी ქართული 日本語 한국어}$$',
        "cyrillic_fallback"
      ],
      "a formula with an error" => [
        'Compare $$\frac{1$$ with the next line.',
        "katex-error"
      ]
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
end
