require "rails_helper"

RSpec.describe(ManuscriptPageRenderer) do
  describe ".render_first_page" do
    it "renders the page as a PNG" do
      png = described_class.render_first_page("#{SPEC_FILES}/manuscript.pdf")

      image = Vips::Image.new_from_file(png.path)
      expect(image.width).to be_positive
      expect(image.height).to be_positive
    ensure
      png&.close!
    end

    it "does not go through libvips, whose PDF loader stays blocked" do
      expect { Vips::Image.pdfload("#{SPEC_FILES}/manuscript.pdf") }
        .to raise_error(Vips::Error, /blocked/)

      png = described_class.render_first_page("#{SPEC_FILES}/manuscript.pdf")
      expect(File.size(png.path)).to be_positive
    ensure
      png&.close!
    end

    it "raises when the file is not a document mutool can draw" do
      expect { described_class.render_first_page("#{SPEC_FILES}/toc.vtt") }
        .to raise_error(described_class::RenderError, /exited with 1/)
    end

    it "raises when mutool reports success but writes nothing" do
      allow(Process).to receive(:spawn).and_return(4321)
      allow(Process).to receive(:wait2).and_return([4321, instance_double(Process::Status,
                                                                          success?: true)])

      expect { described_class.render_first_page("#{SPEC_FILES}/manuscript.pdf") }
        .to raise_error(described_class::RenderError, /no output/)
    end

    it "raises when mutool is missing" do
      allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)

      expect { described_class.render_first_page("#{SPEC_FILES}/manuscript.pdf") }
        .to raise_error(described_class::RenderError, /not installed/)
    end

    it "kills the process group and raises when mutool hangs" do
      allow(Process).to receive(:spawn).and_return(4321)
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      allow(Process).to receive(:kill)
      allow(Process).to receive(:wait)

      expect { described_class.render_first_page("#{SPEC_FILES}/manuscript.pdf") }
        .to raise_error(described_class::RenderError, /timed out/)

      expect(Process).to have_received(:kill).with("TERM", -4321)
    end
  end
end
