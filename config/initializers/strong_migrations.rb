if Rails.env.development? && ENV["STRONG_MIGRATIONS_CHECKS"] == "1"
  require "strong_migrations"

  # Existing migration history should remain replayable without retroactive
  # failures from newly introduced rules.
  StrongMigrations.start_after = 20_260_614_000_001

  # Rollback safety is part of the deploy policy, so check down migrations too.
  StrongMigrations.check_down = true
end
