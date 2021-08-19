/// <reference types="cypress" />
// ***********************************************************
// This example plugins/index.js can be used to load plugins
//
// You can change the location of this file or turn off loading
// the plugins file with the 'pluginsFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/plugins-guide
// ***********************************************************

// This function is called when a project is opened or re-opened (e.g. due to
// the project's config changing)

// cypress/plugins/index.js
/// <reference types="cypress" />
const ms = require('smtp-tester')

/**
 * @type {Cypress.PluginConfig}
 */
module.exports = (on, config) => {
  // starts the SMTP server at localhost:7777
  const port = 1025
  const mailServer = ms.init(port)
  console.log('mail server at port %d', port)
  let lastEmail = {}
  // process all emails
  mailServer.bind((addr, id, email) => {
    console.log('--- email ---')
    console.log(addr, id, email.body)
    lastEmail[email.headers.to] = email
  })
  on('task', {
    resetEmails(email) {
      console.log('reset all emails')
      if (email) {
        delete lastEmail[email]
      } else {
        lastEmail = {}
      }
      return null
    },

    getLastEmail(email) {
      // cy.task cannot return undefined
      // thus we return null as a fallback
      console.log(email)
      console.log(Object.keys(lastEmail))
      //console.log(lastEmail[email])
      return lastEmail[email] || null
    },
  })
}