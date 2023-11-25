if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.cypress_folder = File.expand_path("#{__dir__}/../../spec/cypress")
    # WARNING!! CypressOnRails can execute arbitrary ruby code
    # rubocop:todo Layout/LineLength
    # please use with extra caution if enabling on hosted servers or starting your local server on 0.0.0.0
    # rubocop:enable Layout/LineLength
    c.use_middleware = Rails.env.test?
    c.logger = Rails.logger
  end
end
