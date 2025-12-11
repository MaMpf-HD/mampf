# Try out this file by running
# $ UNI_ID=abc123 UNI_PASSWORD=my-uni-password rails runner app/active-directory-hd-trial.rb
#
# rubocop:disable Rails/Output

require "net/ldap"

BASE = "DC=ad,DC=uni-heidelberg,DC=de".freeze

# Constructs the user principal name for a given university ID.
#
# See: https://ldapwiki.com/wiki/Wiki.jsp?page=UserPrincipalName
def user_principle_name(uni_id)
  "#{uni_id}@uni-heidelberg.de"
end

def show_user_attributes(ldap, uni_id)
  filter = Net::LDAP::Filter.eq("userPrincipalName", user_principle_name(uni_id))
  ldap.search(base: BASE,
              filter: filter,
              attributes: [:displayname, :cn]) do |entry|
    uni_id = entry[:cn].first
    displayname = entry[:displayname].first

    puts "University ID: #{uni_id}"
    puts "Display Name: #{displayname}"
  end
end

# Authenticates a user against Heidelberg University's Active Directory.
#
# For more information, refer to:
# https://www.urz.uni-heidelberg.de/de/service-katalog/identity-management/active-directory
def authenticate_uni_heidelberg_user(uni_id, password)
  # otherwise, the authentication would succeed for empty passwords (!)
  if password.nil? || password.strip.empty?
    puts "Password cannot be empty"
    return false
  end

  ldap = Net::LDAP.new
  # https://www.urz.uni-heidelberg.de/de/service-katalog/identity-management/active-directory
  ldap.host = "ad.uni-heidelberg.de"
  ldap.port = 389
  ldap.auth(user_principle_name(uni_id), password)
  if ldap.bind
    puts "Authentication successful for user #{uni_id}"
    show_user_attributes(ldap, uni_id)
  else
    puts "Authentication failed for user #{uni_id}"
  end
end

uni_id = ENV.fetch("UNI_ID")
password = ENV.fetch("UNI_PASSWORD")
authenticate_uni_heidelberg_user(uni_id, password)

# rubocop:enable Rails/Output
