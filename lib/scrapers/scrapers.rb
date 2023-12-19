require "nokogiri"
require "open-uri"
require "openssl"

# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class CamtasiaScraper
  def initialize(link)
    html = Nokogiri::HTML(URI.parse(link).open)

    # find xml and init the tree if to be found
    if html.search("iframe").empty?
      xml_file = /setXMPSrc\("(.*?)"\)/.match(html)[1]
      xml_text = URI.parse(URI.join(link, xml_file)).open
      @xml = Nokogiri::XML(xml_text).remove_namespaces!
    # follow the iframe if we have one
    else
      src = html.search("iframe").first["src"]
      initialize(URI.join(link, src))
    end
  end

  def toc
    @xml.search('Description[@trackType="TableOfContents"]/markers/Seq/li/Description').map do |i|
      { start_time: i.xpath("@startTime").to_s.to_i, text: i.xpath("@name").to_s }
    end
  end

  def references
    @xml.search('Description[@trackType="Hotspot"]/markers/Seq/li/Description').map do |i|
      { start_time: i.xpath("@startTime").to_s.to_i, link: i.xpath("@location").to_s }
    end
  end

  def to_h
    { toc: toc, references: references }
  end
end
