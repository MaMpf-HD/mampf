# Try out this file by running
# $ UNI_ID=abc123 UNI_PASSWORD=my-uni-password rails runner bin/active-directory-hd-trial.rb

require "net/ldap"

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
  ldap.auth "#{uni_id}@uni-heidelberg.de", password
  if ldap.bind
    puts "Authentication successful for user #{uni_id}"
    true
  else
    puts "Authentication failed for user #{uni_id}"
    false
  end
end

uni_id =  ENV.fetch("UNI_ID")
password = ENV.fetch("UNI_PASSWORD")
authenticate_uni_heidelberg_user(uni_id, password)
