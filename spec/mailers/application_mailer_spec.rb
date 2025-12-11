require "rails_helper"
require "tmpdir"

RSpec.describe(ApplicationMailer, type: :mailer) do
  describe "#mail" do
    let(:temp_view_path) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(temp_view_path)
    end

    let(:mailer_class) do
      Class.new(ApplicationMailer) do
        # Set a custom default template_path, similar to ExceptionHandler::ExceptionMailer
        default template_path: "special_location"
        layout nil

        def test_email
          mail(to: "test@example.org", subject: "Test") # rubocop:disable Rails/I18nLocaleTexts
        end

        # Override name so that ApplicationMailer logic for 'usual_rails_path' works
        def self.name
          "UniqueTestMailer"
        end
      end
    end

    it "includes the default template_path in the view lookup" do
      # Create a template in the directory specified by `default template_path`
      # Structure: <view_path>/<template_path>/<action>.html.erb
      target_dir = File.join(temp_view_path, "special_location")
      FileUtils.mkdir_p(target_dir)
      File.write(File.join(target_dir, "test_email.html.erb"), "Content from special location")

      # Add the temp dir to the view paths so Rails can find the file
      mailer_class.prepend_view_path(temp_view_path)

      # Execute
      email = mailer_class.test_email

      # Verify that the template was found in the 'special_location'
      expect(email.body.encoded).to include("Content from special location")
    end

    it "includes the custom path (pluralized folder/mails) in the view lookup" do
      # custom_path = "unique_tests/mails"
      target_dir = File.join(temp_view_path, "unique_tests", "mails")
      FileUtils.mkdir_p(target_dir)
      File.write(File.join(target_dir, "test_email.html.erb"), "Content from custom path")

      mailer_class.prepend_view_path(temp_view_path)
      email = mailer_class.test_email
      expect(email.body.encoded).to include("Content from custom path")
    end

    it "includes the usual rails path in the view lookup" do
      # usual_rails_path = "unique_test_mailer"
      target_dir = File.join(temp_view_path, "unique_test_mailer")
      FileUtils.mkdir_p(target_dir)
      File.write(File.join(target_dir, "test_email.html.erb"), "Content from usual path")

      mailer_class.prepend_view_path(temp_view_path)
      email = mailer_class.test_email
      expect(email.body.encoded).to include("Content from usual path")
    end
  end

  describe "defaults" do
    let(:mailer_class) do
      Class.new(ApplicationMailer) do
        def test_email
          mail(to: "test@example.org", subject: "Test", body: "Test Body") # rubocop:disable Rails/I18nLocaleTexts
        end

        def self.name
          "UniqueTestMailer"
        end
      end
    end

    it "sets the default from address" do
      email = mailer_class.test_email
      expect(email.from).to eq([DefaultSetting::PROJECT_EMAIL])
    end

    it "sets a custom Message-ID with the configured domain" do
      stub_const("ENV", ENV.to_hash.merge("MAILID_DOMAIN" => "mampf.test"))
      email = mailer_class.test_email
      expect(email.message_id).to end_with("@mampf.test")
    end
  end
end
