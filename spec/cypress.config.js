const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    baseUrl: "http://localhost:3000",
    defaultCommandTimeout: 10000,
    projectId: "v45wg9",
    retries: {
      runMode: 2,
      openMode: 0,
    },
  },
});
