# Try out this file by running
# $ UNI_ID=abc123 UNI_PASSWORD=my-uni-password rails runner app/uni_heidelberg.rb
#
# rubocop:disable Rails/Output

require "net/ldap"

LDAP_HOST = "ad.uni-heidelberg.de".freeze
LDAP_PORT = 389
LDAP_BASE = "DC=ad,DC=uni-heidelberg,DC=de".freeze

# Shows user attributes for a given university ID.
#
# See: https://ldapwiki.com/wiki/Wiki.jsp?page=UserPrincipalName
def user_principle_name(uni_id)
  "#{uni_id}@uni-heidelberg.de"
end

def show_user_attributes(ldap, uni_id)
  filter = Net::LDAP::Filter.eq("userPrincipalName", user_principle_name(uni_id))
  ldap.search(base: LDAP_BASE,
              filter: filter,
              attributes: [:displayname, :cn, :objectclass,
                           :givenname, :sn, :whencreated, :whenchanged,
                           :pwdlastset, :lastlogontimestamp, :mail]) do |entry|
    uni_id = entry[:cn].first
    displayname = entry[:displayname].first
    roles = entry[:objectclass]
    first_name = entry[:givenname].first
    last_name = entry[:sn].first
    created_at = entry[:whencreated].first
    changed_at = entry[:whenchanged].first
    password_last_set = entry[:pwdlastset].first
    last_login = entry[:lastlogontimestamp].first
    mail = entry[:mail].first

    puts "University ID: #{uni_id}"
    puts "Display Name: #{displayname}"
    puts "Roles: #{roles.join(", ")}"
    puts "First Name: #{first_name}"
    puts "Last Name: #{last_name}"
    puts "Created At: #{created_at}"
    puts "Changed At: #{changed_at}"
    puts "Password Last Set: #{password_last_set}"
    puts "Last Login: #{last_login}"
    puts "Email: #{mail}"
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
  ldap.host = LDAP_HOST
  ldap.port = LDAP_PORT
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
