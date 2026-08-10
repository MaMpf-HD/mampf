module Demo
  module QuietLoggingSupport
    module_function

    def with_quiet_logging
      old_level = ActiveRecord::Base.logger&.level
      ActiveRecord::Base.logger&.level = :warn
      yield
    ensure
      ActiveRecord::Base.logger&.level = old_level
    end
  end
end
