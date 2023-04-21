# frozen_string_literal: true

# spec/support/simplecov_helper.rb
# Credit goes to https://gitlab.com/gitlab-org/gitlab-foss/blob/master/spec/simplecov_env.rb

require 'simplecov'
require 'active_support/core_ext/numeric/time'

module SimpleCovHelper
  def self.configure_profile
    SimpleCov.configure do
      load_profile 'test_frameworks'
      track_files '{app,lib,config}/**/*.rb'
      track_files 'db/seeds.rb'

      add_filter '/vendor/ruby/'
      add_filter 'spec/'

      add_group 'Libraries',         'lib'
      add_group 'Assets',            'app/assets'
      add_group 'Channels',          'app/channels'
      add_group 'Netzke Components', 'app/components'
      add_group 'Controllers',       'app/controllers'
      add_group 'Helpers',           'app/helpers'
      add_group 'Jobs',              'app/jobs'
      add_group 'Models',            'app/models'
      add_group 'Services',          'app/services'
      add_group 'Views',             'app/views'

      use_merging true
      merge_timeout 5.days
    end
  end

  def self.start!
    return unless ENV['COVERAGE'] == 'true'

    configure_profile

    SimpleCov.start
  end
end
