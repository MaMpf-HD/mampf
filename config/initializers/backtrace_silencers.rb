# Be sure to restart your server when you modify this file.

# rubocop:todo Layout/LineLength
# You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
# rubocop:enable Layout/LineLength
# Rails.backtrace_cleaner.add_silencer { |line| /my_noisy_library/.match?(line) }

# rubocop:todo Layout/LineLength
# You can also remove all the silencers if you're trying to debug a problem that might stem from framework code
# rubocop:enable Layout/LineLength
# rubocop:todo Layout/LineLength
# by setting BACKTRACE=1 before calling your invocation, like "BACKTRACE=1 ./bin/rails runner 'MyClass.perform'".
# rubocop:enable Layout/LineLength
Rails.backtrace_cleaner.remove_silencers! if ENV["BACKTRACE"]
