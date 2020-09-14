User.create(name: "Max Mustermann",email:"max@mampf.edu",password:"test123456",  consents:true).confirm()
p FactoryBot.create_list(:course,10)