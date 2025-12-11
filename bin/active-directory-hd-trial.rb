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

    default_naming_context = nil
    ldap.search(base: "",
      scope: Net::LDAP::SearchScope_BaseObject,
      attributes: ["defaultNamingContext"]) do |entry|
      if entry["defaultNamingContext"] && entry["defaultNamingContext"].any?
        default_naming_context = entry["defaultNamingContext"].first
      end
    end

    base = default_naming_context || ""
    filter = Net::LDAP::Filter.eq("userPrincipalName", "#{uni_id}@uni-heidelberg.de") | Net::LDAP::Filter.eq("sAMAccountName", uni_id)
    entries = []

    ldap.search(base: base, filter: filter, attributes: ['*', '+']) do |entry|
      entries << entry
    end

    if entries.empty?
      puts "No LDAP entries found for user #{uni_id}"
    else
      entries.each do |entry|
        puts "LDAP entry: #{entry.dn}"
        entry.each do |attribute, values|
          puts "#{attribute}: #{values.join(', ')}"
        end
      end
    end
    true
  else
    puts "Authentication failed for user #{uni_id}"
    false
  end
end

uni_id =  ENV.fetch("UNI_ID")
password = ENV.fetch("UNI_PASSWORD")
authenticate_uni_heidelberg_user(uni_id, password)
