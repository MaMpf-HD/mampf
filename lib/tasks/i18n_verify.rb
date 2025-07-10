# rubocop:disable Rails/Output

require "yaml"

module I18nVerify
  # Helper to detect duplicate keys in a YAML file
  module YamlDuplicateKeyDetector
    class DuplicateKeyHandler < Psych::Handler
      def initialize
        super
        @stack = []
        @duplicates = []
        @expecting_value = false
      end
      attr_reader :duplicates

      def start_mapping(*)
        @stack.push(Set.new)
      end

      def end_mapping(*)
        @stack.pop
      end

      def scalar(value, *)
        return unless @stack.any? && !@expecting_value

        if @stack.last.include?(value)
          @duplicates << value
        else
          @stack.last << value
        end
      end

      def mapping_key(*)
        @expecting_value = false
      end

      def mapping_value(*)
        @expecting_value = true
      end
    end

    def self.duplicates_in_file(filename)
      handler = DuplicateKeyHandler.new
      File.open(filename, "r") do |f|
        parser = Psych::Parser.new(handler)
        parser.parse(f)
      end
      handler.duplicates.uniq
    rescue StandardError => e
      warn("YAML parse error in #{filename}: #{e}")
      []
    end
  end

  class Checker
    def initialize(filenames)
      @filenames = filenames
    end

    def duplicates
      any_duplicates_found = false
      @filenames.each do |filename|
        next if filename.include?("gem")

        duplicates = YamlDuplicateKeyDetector.duplicates_in_file(filename)
        next if duplicates.empty?

        any_duplicates_found = true
        puts "\n▶ Duplicate keys in #{filename}:"
        duplicates.each { |key| puts "  #{key}" }
      end
      puts "No duplicate keys found." unless any_duplicates_found
    end
  end
end

# rubocop:enable Rails/Output
