require "zip"

module Seeds
  # Packs the uploads that belong to the seed data: the files its records point
  # at, and nothing else. A development store collects far more than that over
  # time, and an archive built by hand keeps files of models that have since
  # been removed -- both of which the published set has suffered from.
  module PackageSupport
    module_function

    ARCHIVE_ROOT = "uploads".freeze

    def package!(path: default_path)
      ensure_development!
      files = referenced_files
      missing = files.reject { |file| File.exist?(file) }

      write_archive!(path, files - missing)
      report!(path, files.size, missing)
      missing
    end

    # Everything the records point at: each Shrine attachment, the derivatives
    # hanging off it, and the blobs ActiveStorage keeps for rich text.
    def referenced_files
      Rails.application.eager_load!
      files = attachment_files + blob_files
      files.uniq
    end

    def attachment_files
      attachment_models.flat_map do |model|
        columns = model.column_names.select { |column| column.end_with?("_data") }
        model.find_each.flat_map do |record|
          columns.flat_map { |column| paths_in(parse(record[column])) }
        end
      end
    end

    def blob_files
      ActiveStorage::Blob.find_each.map { |blob| blob.service.path_for(blob.key) }
    end

    def attachment_models
      ApplicationRecord.descendants.select do |model|
        !model.abstract_class? && model.table_exists? &&
          model.column_names.any? { |column| column.end_with?("_data") }
      end
    end

    def paths_in(data)
      return [] unless data.is_a?(Hash)

      own = storage_path(data["storage"], data["id"])
      derived = data["derivatives"].to_h.values.flat_map { |child| paths_in(child) }

      [own, *derived].compact
    end

    def storage_path(storage, id)
      return if storage.blank? || id.blank?

      storage = Shrine.storages[storage.to_sym]
      return unless storage.respond_to?(:path)

      storage.path(id).to_s
    end

    def parse(value)
      return value if value.is_a?(Hash)
      return if value.blank?

      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    def write_archive!(path, files)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.rm_f(path)
      root = Rails.public_path.to_s

      Zip::File.open(path, create: true) do |archive|
        files.sort.each do |file|
          archive.add(File.join(ARCHIVE_ROOT, relative_to_uploads(file, root)), file)
        end
      end
    end

    # The archive is unpacked over `public/`, so it carries the same layout.
    def relative_to_uploads(file, root)
      file.sub("#{root}/#{ARCHIVE_ROOT}/", "")
    end

    def default_path
      Rails.root.join("db/backups/development/uploads.zip").to_s
    end

    # rubocop:disable Rails/Exit
    def ensure_development!
      return if Rails.env.development?

      abort("This packs the development seed: refusing to run in #{Rails.env}.")
    end
    # rubocop:enable Rails/Exit

    def report!(path, wanted, missing)
      Rails.logger.debug do
        "Packed #{wanted - missing.size} of #{wanted} referenced files into #{path}"
      end
      missing.each { |file| Rails.logger.debug { "Missing: #{file}" } }
    end
  end
end
