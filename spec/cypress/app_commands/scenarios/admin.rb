# frozen_string_literal: true

User.create(name: 'Admin', email: 'administrator@mampf.edu',
            password: 'test123456', admin: true, consents: true).confirm
