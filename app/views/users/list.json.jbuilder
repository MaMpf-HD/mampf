json.array! @users do |user|
  json.id user.id
  json.text user.info
end