namespace :maintenance do
  desc "Regenerate ActionText SGIDs for ActiveStorage attachments after secret_key_base change"
  task fix_action_text_sgids: :environment do
    require "nokogiri"

    Rails.logger.debug("Starting ActionText SGID repair...")
    count = 0

    host = Rails.env.production? ? ENV.fetch("URL_HOST", "localhost") : "localhost:3000"
    protocol = Rails.env.production? ? "https" : "http"
    url_options = { host: host, protocol: protocol }

    ActionText::RichText.find_each do |rich_text|
      next if rich_text.body.blank?

      # Parse the raw HTML body
      doc = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_s)
      changed = false

      doc.css("action-text-attachment").each do |node|
        # We try to recover ActiveStorage attachments which are linked via the 'embeds' association.
        # Note: This script does not fix 'Mentions' (e.g. User references) as they are not stored
        #  in active_storage_attachments.

        filename = node["filename"]
        filesize = node["filesize"]

        # Find the corresponding blob in the associated attachments for this specific
        # RichText record. We match based on filename and size since we can't decode the old SGID
        blob = rich_text.embeds.blobs.find do |b|
          (b.filename.to_s == filename) && (b.byte_size.to_s == filesize)
        end

        if blob
          # Generate a new SGID with the current secret_key_base
          new_sgid = blob.attachable_sgid

          if node["sgid"] != new_sgid
            node["sgid"] = new_sgid
            changed = true
          end

          # Update the URL as well, as it contains a signed_id that is now invalid
          if node["url"]

            new_url = Rails.application.routes.url_helpers.rails_blob_url(blob, url_options)

            if node["url"] != new_url
              node["url"] = new_url
              changed = true
            end
          end
        else
          Rails.logger
               .warn("Could not find blob for #{filename} in RichText #{rich_text.id}")
        end
      end

      if changed
        # Update the body column directly to avoid callbacks/validations
        rich_text.update_column(:body, doc.to_html) # rubocop:disable Rails/SkipsModelValidations
        count += 1
        Rails.logger.debug(".")
      end
    end

    Rails.logger.debug { "\nDone. Fixed #{count} RichText records." }
  end
end
