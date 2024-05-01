# See the docs here: https://www.rubydoc.info/github/DatabaseCleaner/database_cleaner
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation, except: ["ar_internal_metadata"])
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
