require "rails_helper"

RSpec.describe(Xkcd) do
  let(:latest) { StringIO.new({ num: 3 }.to_json) }
  let(:image) do
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.content_type = "image/png"
      response.instance_variable_set(:@body, "png-bytes")
      response.instance_variable_set(:@read, true)
    end
  end

  def comic(img)
    StringIO.new({ num: 2, title: "Title", alt: "Alt", img: img }.to_json)
  end

  before do
    allow(described_class).to receive(:rand).and_return(1)
    allow(URI).to receive(:open).with("https://xkcd.com/info.0.json").and_return(latest)
  end

  it "embeds the comic so that the browser does not load it from xkcd" do
    url = "https://imgs.xkcd.com/comics/title.png"
    allow(URI).to receive(:open).with("https://xkcd.com/2/info.0.json").and_return(comic(url))
    allow(Net::HTTP).to receive(:start)
      .with("imgs.xkcd.com", 443, use_ssl: true, open_timeout: 5, read_timeout: 5)
      .and_return(image)

    expect(described_class.random["img_data"])
      .to eq("data:image/png;base64,#{Base64.strict_encode64("png-bytes")}")
  end

  it "fetches images from xkcd's image host only" do
    allow(URI).to receive(:open).with("https://xkcd.com/2/info.0.json")
                                .and_return(comic("https://example.com/x.png"))

    expect(described_class.random).to have_key(:error)
  end
end
