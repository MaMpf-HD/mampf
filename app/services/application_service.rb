# ApplicationService is a base class for all services in the application.
# See https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial
class ApplicationService
  def self.call(...)
    new(...).call
  end

  def initialize(*args)
  end
end
