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

  def stub_image_request
    http = instance_double(Net::HTTP)
    allow(http).to receive(:get).with("/comics/title.png").and_return(image)
    allow(Net::HTTP).to receive(:start)
      .with("imgs.xkcd.com", 443, use_ssl: true, open_timeout: 5, read_timeout: 5)
      .and_yield(http)
  end

  it "embeds the comic so that the browser does not load it from xkcd" do
    url = "https://imgs.xkcd.com/comics/title.png"
    allow(URI).to receive(:open).with("https://xkcd.com/2/info.0.json").and_return(comic(url))
    stub_image_request

    expect(described_class.random["img_data"])
      .to eq("data:image/png;base64,#{Base64.strict_encode64("png-bytes")}")
  end

  # The comic is fetched while the quiz's last page is rendered.
  it "goes without the comic when xkcd takes longer than the deadline" do
    stub_const("Xkcd::DEADLINE", 0.05)
    slow_comic = comic("https://imgs.xkcd.com/comics/title.png")
    allow(URI).to receive(:open).with("https://xkcd.com/2/info.0.json") do
      sleep(0.5)
      slow_comic
    end
    stub_image_request

    expect(described_class.random).to have_key(:error)
  end

  it "fetches images from xkcd's image host only" do
    allow(URI).to receive(:open).with("https://xkcd.com/2/info.0.json")
                                .and_return(comic("https://example.com/x.png"))

    expect(described_class.random).to have_key(:error)
  end
end
