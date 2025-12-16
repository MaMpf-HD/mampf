# Usage:
#   bundle exec rails "maintenance:fix_action_text_sgids[OLD_SECRET_KEY_BASE]"
#
# Arguments:
#   OLD_SECRET_KEY_BASE (optional): The previous secret_key_base. If provided, the task
#                                   will deterministically decode old SGIDs to find the
#                                   correct blob. If omitted, it falls back to a heuristic
#                                   matching filename and filesize.
#
# related:
# https://github.com/rails/rails/pull/39623
# https://github.com/rails/rails/issues/40435#issuecomment-903398832
# https://discuss.rubyonrails.org/t/how-to-rotate-secrek-key-base-without-breaking-activestorage-actiontext-attachments/80865
namespace :maintenance do
  desc "Regenerate ActionText SGIDs for ActiveStorage attachments after secret_key_base change"
  task :fix_action_text_sgids, [:old_secret_key_base] => :environment do |_, args|
    require "nokogiri"

    Rails.logger.debug("Starting ActionText SGID repair...")
    count = 0

    host = ENV.fetch("URL_HOST")
    protocol = Rails.env.production? ? "https" : "http"
    url_options = { host: host, protocol: protocol }

    # Setup Old Verifier (if key is provided)
    old_verifier = nil
    if args[:old_secret_key_base].present?
      # Replicate Rails key derivation logic
      keygen = ActiveSupport::KeyGenerator.new(args[:old_secret_key_base], iterations: 1000)
      secret = keygen.generate_key("signed_global_ids")
      old_verifier = ActiveSupport::MessageVerifier.new(secret, serializer: JSON)
    end

    ActionText::RichText.with_attached_embeds.find_each do |rich_text|
      next if rich_text.body.blank?

      doc = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_s)
      changed = false

      doc.css("action-text-attachment").each do |node|
        filename = node["filename"]
        filesize = node["filesize"]
        blob = nil

        # Strategy A: Try to decode old SGID (Deterministic)
        if old_verifier && node["sgid"].present?
          begin
            payload = old_verifier.verify(node["sgid"], purpose: "attachable")
            # Payload is usually a hash: {"gid"=>"...", "purpose"=>"attachable"}
            gid_string = payload.is_a?(Hash) ? payload["gid"] : payload

            if gid_string
              gid = GlobalID.parse(gid_string)
              blob = rich_text.embeds.blobs.find { |b| b.id == gid.model_id.to_i } if gid
              if blob
                Rails.logger.debug do
                  "Strategy A: Decoded SGID for #{filename} -> Blob #{blob&.id}"
                end
              end
            end
          rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageVerifier::InvalidMessage
            Rails.logger.warn("Old secret key provided but failed to verify SGID " \
                              "for #{filename}. Falling back to heuristic.")
          end
        end

        # Strategy B: Fallback to Filename/Size Heuristic
        unless blob
          blob = rich_text.embeds.blobs.find do |b|
            (b.filename.to_s == filename) && (b.byte_size.to_s == filesize)
          end
          if blob
            Rails.logger.debug { "Strategy B: Heuristic match for #{filename} -> Blob #{blob&.id}" }
          end
        end

        if blob
          # Fix SGID
          new_sgid = blob.attachable_sgid
          if node["sgid"] != new_sgid
            node["sgid"] = new_sgid
            changed = true
          end

          # Fix URL (Always absolute based on config)
          if node["url"]
            current_url = node["url"]
            new_url = Rails.application.routes.url_helpers.rails_blob_url(blob, url_options)

            if current_url != new_url
              node["url"] = new_url
              changed = true
            end
          end
        else
          Rails.logger
               .warn("Could not find attachment for #{filename} in RichText #{rich_text.id}")
          next
        end

        # Generate a new SGID with the current secret_key_base
        new_sgid = blob.attachable_sgid

        if node["sgid"] != new_sgid
          node["sgid"] = new_sgid
          changed = true
        end

        # Update the URL as well, as it contains a signed_id that is now invalid
        next unless node["url"]

        new_url = Rails.application.routes.url_helpers.rails_blob_url(blob, url_options)

        if node["url"] != new_url
          node["url"] = new_url
          changed = true
        end
      end

      if changed
        rich_text.update_column(:body, doc.to_html) # rubocop:disable Rails/SkipsModelValidations
        count += 1
        Rails.logger.debug { "Updated #{count} records..." } if (count % 100).zero?
      end
    end

    Rails.logger.debug { "\nDone. Fixed #{count} RichText records." }
  end
end
