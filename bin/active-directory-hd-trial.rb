require "net/ldap"

def authenticate_uni_heidelberg_user(uni_id, password)
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

UNI_ID = "ab123"
PASSWORD = "secret-password"
authenticate_uni_heidelberg_user(UNI_ID, PASSWORD)

# Run via
# $ rails runner bin/active-directory-hd-trial.rb