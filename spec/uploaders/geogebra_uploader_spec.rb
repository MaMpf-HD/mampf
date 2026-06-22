require "rails_helper"
require "stringio"
require "zip"

RSpec.describe(GeogebraUploader) do
  def fixture_contents(name)
    Rails.root.join(SPEC_FILES, name).binread
  end

  def geogebra_archive(extension: ".ggb", entries: {})
    Tempfile.new(["upload", extension]).tap do |file|
      Zip::OutputStream.open(file.path) do |zip|
        entries.each do |name, content|
          zip.put_next_entry(name)
          zip.write(content)
        end
      end
      file.open
      file.binmode
      file.rewind
    end
  end

  def oversized_geogebra_archive
    geogebra_archive(entries: {
                       "geogebra.xml" => "<geogebra />"
                     }).tap do |file|
      file.truncate(GeogebraUploader::MAX_SIZE + 1)
      file.rewind
    end
  end

  def screenshot_derivative_for(medium)
    medium.geogebra_attacher.derivatives[:screenshot] ||
      medium.geogebra_attacher.derivatives["screenshot"]
  end

  it "accepts valid ggb archives and generates a screenshot derivative" do
    medium = build(:valid_medium)
    file = geogebra_archive(entries: {
                              "geogebra.xml" => "<geogebra />",
                              "geogebra_thumbnail.png" => fixture_contents("image.png")
                            })

    medium.geogebra = file

    expect(medium).to be_valid
    expect { medium.geogebra_derivatives! }.not_to raise_error
    expect(screenshot_derivative_for(medium).metadata["mime_type"]).to eq("image/png")
  ensure
    file&.close!
  end

  it "rejects archives without the ggb extension" do
    medium = build(:valid_medium)
    file = geogebra_archive(extension: ".zip", entries: {
                              "geogebra.xml" => "<geogebra />"
                            })

    medium.geogebra = file

    expect(medium).not_to be_valid
    expect(medium.errors[:geogebra]).to include(
      I18n.t("submission.wrong_file_type",
             file_type: ".zip",
             accepted_file_type: ".ggb")
    )
  ensure
    file&.close!
  end

  it "rejects archives without geogebra.xml" do
    medium = build(:valid_medium)
    file = geogebra_archive(entries: {
                              "geogebra_thumbnail.png" => fixture_contents("image.png")
                            })

    medium.geogebra = file

    expect(medium).not_to be_valid
    expect(medium.errors[:geogebra]).to include(I18n.t("geogebra.invalid_archive"))
  ensure
    file&.close!
  end

  it "rejects archives with oversized thumbnail entries" do
    medium = build(:valid_medium)
    file =
      geogebra_archive(entries: {
                         "geogebra.xml" => "<geogebra />",
                         "geogebra_thumbnail.png" =>
                           "A" * (GeogebraUploader::MAX_THUMBNAIL_SIZE + 1)
                       })

    medium.geogebra = file

    expect(medium).not_to be_valid
    expect(medium.errors[:geogebra]).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end

  it "rejects oversized geogebra archives" do
    medium = build(:valid_medium)
    file = oversized_geogebra_archive

    medium.geogebra = file

    expect(medium).not_to be_valid
    expect(medium.errors[:geogebra]).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end

  it "keeps missing thumbnails non-fatal during derivative generation" do
    medium = build(:valid_medium)
    file = geogebra_archive(entries: {
                              "geogebra.xml" => "<geogebra />"
                            })

    medium.geogebra = file

    expect(medium).to be_valid
    expect { medium.geogebra_derivatives! }.not_to raise_error
    expect(screenshot_derivative_for(medium)).to be_nil
  ensure
    file&.close!
  end

  it "ignores invalid thumbnail payloads during derivative generation" do
    medium = build(:valid_medium)
    file = geogebra_archive(entries: {
                              "geogebra.xml" => "<geogebra />",
                              "geogebra_thumbnail.png" => fixture_contents("manuscript.pdf")
                            })

    medium.geogebra = file

    expect(medium).to be_valid
    expect { medium.geogebra_derivatives! }.not_to raise_error
    expect(screenshot_derivative_for(medium)).to be_nil
  ensure
    file&.close!
  end

  it "drops thumbnails whose extracted bytes exceed the limit" do
    file = Tempfile.new(["upload", ".ggb"])
    thumbnail_entry = instance_double(Zip::Entry, directory?: false, size: 1)
    zip_file = instance_double(Zip::File)

    allow(zip_file).to receive(:find_entry)
      .with(GeogebraUploader::THUMBNAIL_ENTRY)
      .and_return(thumbnail_entry)
    allow(thumbnail_entry).to receive(:get_input_stream)
      .and_yield(StringIO.new("A" * (GeogebraUploader::MAX_THUMBNAIL_SIZE + 1)))
    allow(Zip::File).to receive(:open).and_yield(zip_file)
    allow(described_class).to receive(:validated_thumbnail_file)

    result = described_class.build_screenshot_derivative(file)

    expect(result).to be_nil
    expect(described_class).not_to have_received(:validated_thumbnail_file)
  ensure
    file&.close!
  end
end
