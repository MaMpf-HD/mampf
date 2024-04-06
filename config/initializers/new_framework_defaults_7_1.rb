# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.1`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# 💥✅ I've removed the lines in this file where I agree with the new defaults
# or when they are not applicable to us. I've kept the lines that I'm not sure about
# or that I think we should discuss.
# TODO: We still have to activate the new defaults by setting
# `config.load_defaults` to `7.1` (!)

# ❓ Parameters Hash -- Not sure whether this affects us
###
# Do not treat an `ActionController::Parameters` instance
# as equal to an equivalent `Hash` by default.
#++
# Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality = false

# ❓❗ SHA-256 as new hash algorithm -- TODO: check what we should do with this
###
# Active Record Encryption now uses SHA-256 as its hash digest algorithm.
#
# There are 3 scenarios to consider.
#
# 1. If you have data encrypted with previous Rails versions, and you have
# +config.active_support.key_generator_hash_digest_class+ configured as SHA1 (the default
# before Rails 7.0), you need to configure SHA-1 for Active Record Encryption too:
#++
# Rails.application.config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA1
#
# 2. If you have +config.active_support.key_generator_hash_digest_class+ configured as SHA256
# (the new default in 7.0), then you need to configure SHA-256 for Active Record Encryption:
#++
# Rails.application.config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256
#
# 3. If you don't currently have data encrypted with Active Record encryption, you can disable this
# setting to configure the default behavior starting 7.1+:
#++
# Rails.application.config.active_record.encryption.support_sha1_for_non_deterministic_encryption
# = false

# ❓ Invalid cache expiration time, what behavior do we want?
###
# Specify if an `ArgumentError` should be raised if `Rails.cache` `fetch` or
# `write` are given an invalid `expires_at` or `expires_in` time.
# Options are `true`, and `false`. If `false`, the exception will be reported
# as `handled` and logged instead.
#++
# Rails.application.config.active_support.raise_on_invalid_cache_expiration_time = true

# ❓ New default serializer
###
# Specify the default serializer used by `MessageEncryptor` and `MessageVerifier`
# instances.
#
# The legacy default is `:marshal`, which is a potential vector for
# deserialization attacks in cases where a message signing secret has been
# leaked.
#
# In Rails 7.1, the new default is `:json_allow_marshal` which serializes and
# deserializes with `ActiveSupport::JSON`, but can fall back to deserializing
# with `Marshal` so that legacy messages can still be read.
#
# In Rails 7.2, the default will become `:json` which serializes and
# deserializes with `ActiveSupport::JSON` only.
#
# Alternatively, you can choose `:message_pack` or `:message_pack_allow_marshal`,
# which serialize with `ActiveSupport::MessagePack`. `ActiveSupport::MessagePack`
# can roundtrip some Ruby types that are not supported by JSON, and may provide
# improved performance, but it requires the `msgpack` gem.
#
# For more information, see
# https://guides.rubyonrails.org/v7.1/configuring.html#config-active-support-message-serializer
#
# If you are performing a rolling deploy of a Rails 7.1 upgrade, wherein servers
# that have not yet been upgraded must be able to read messages from upgraded
# servers, first deploy without changing the serializer, then set the serializer
# in a subsequent deploy.
#++
# Rails.application.config.active_support.message_serializer = :json_allow_marshal

# ❓ Should discuss what we want here.
# See: https://guides.rubyonrails.org/v7.1/configuring.html#config-active-record-commit-transaction-on-non-local-return
###
# Whether a `transaction` block is committed or rolled back when exited via
# `return`, `break` or `throw`.
#++
# Rails.application.config.active_record.commit_transaction_on_non_local_return = true

# ❗ New cache format -- Add later
###
# ** Please read carefully, this must be configured in config/application.rb **
#
# Change the format of the cache entry.
#
# Changing this default means that all new cache entries added to the cache
# will have a different format that is not supported by Rails 7.0
# applications.
#
# Only change this value after your application is fully deployed to Rails 7.1
# and you have no plans to rollback.
# When you're ready to change format, add this to `config/application.rb` (NOT
# this file):
#   config.active_support.cache_format_version = 7.1
