# Adapted from the i18n-verify gem
# https://github.com/fastcatch/i18n-verify/

# rubocop:disable Rails/Output

module I18nVerify
  class Translations < Array
    def initialize(filenames) # rubocop:disable Lint/MissingSuper
      # Reads files and stores translations (similar to i18n's internals but include filenames)
      filenames.each do |filename|
        # puts "Loading: #{filename}"
        type = File.extname(filename).tr(".", "").downcase.to_sym

        next if type == :rb
        raise(I18n::UnknownFileType.new(type, filename)) unless type == :yml

        data = YAML.unsafe_load_file(filename)

        raise(I18n::InvalidLocaleData, filename) unless data.is_a?(Hash)

        data.each_pair do |locale, d|
          flatten_keys(d || {}) do |flat_key, translation|
            push({ filename: filename, locale: locale.to_s,
                   key: flat_key, translation: translation })
          end
        end
      end
    end

    def select(*args, &)
      if block_given?
        super(&)
      else
        options = args.extract_options!
        super { |h| options.all? { |key, value| h[key] == value } }
      end
    end

    protected

      # Converts translations hash to flat keys
      # i.e. from { :de => {:new => neue, :old => alt} }
      # to [ ['de.new', 'neue'], ['de.old', 'alte'] ]
      # and yields a flat key and the value to the block
      def flatten_keys(hash, prev_key = nil, &block)
        hash.each_pair do |key, value|
          curr_key = [prev_key, key].compact.join(".")
          if value.is_a?(Hash)
            flatten_keys(value, curr_key, &block)
          else
            yield(curr_key, value)
          end
        end
      end
  end

  class Checker
    def initialize(filenames)
      @translations = Translations.new(filenames)
    end

    def duplicates(locales_requested = [])
      locales = @translations.pluck(:locale).uniq
      locales_to_check = locales_requested.empty? ? locales : (locales & locales_requested)

      puts "Checking locales #{locales_to_check.inspect} out of #{locales.inspect} for redundancy"

      # Collect and print duplicate translations
      locales_to_check.each do |locale|
        puts "#{locale}:"
        translations_by_key = @translations.select do |t|
          t[:locale] == locale
        end
        translations_by_key = translations_by_key.uniq.group_by { |t| t[:key] }
        translations_by_key.reject { |_key, value| value.one? }.each_pair do |key, translations|
          puts " #{key}: #{translations.collect { |t| t[:filename] }.join(", ")}"
        end
      end
    end
  end
end

# rubocop:enable Rails/Output
