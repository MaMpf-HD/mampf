require "cgi"

module Cypress
  class MailsPlaywrightController < CypressController
    def create
      recipient = params[:recipient].to_s
      raise(ArgumentError, "recipient must be present") if recipient.blank?

      mail = ActionMailer::Base.deliveries.reverse.find do |delivery|
        delivery.to&.include?(recipient)
      end

      raise("No delivered mail found for #{recipient}") if mail.nil?

      render json: {
        subject: mail.subject,
        to: mail.to,
        text_body: mail.text_part&.body&.to_s,
        html_body: mail.html_part&.body&.to_s || mail.body.to_s,
        urls: extracted_urls(mail)
      }, status: :created
    end

    private

      def extracted_urls(mail)
        [mail.text_part&.body&.to_s, mail.html_part&.body&.to_s, mail.body.to_s]
          .compact
          .flat_map { |body| body.scan(%r{https?://[^\s"'<>]+}) }
          .map { |url| CGI.unescapeHTML(url) }
          .uniq
      end
  end
end
