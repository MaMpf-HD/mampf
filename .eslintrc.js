// Starting with v9, this config will be deprecated in favor of the new
// configuration files [1]. @stylistic is already ready for the new "flat config",
// when it's time, copy the new config from [2].
// [1] https://eslint.org/docs/latest/use/configure/configuration-files-new
// [2] https://eslint.style/guide/config-presets#configuration-factory

// Stylistic Plugin for ESLint
// see the rules in [3] and [4].
// [3] https://eslint.style/packages/js#rules
// [4] https://eslint.org/docs/rules/
const stylistic = require("@stylistic/eslint-plugin");

const customizedStylistic = stylistic.configs.customize({
  "indent": 2,
  "quotes": "double",
  "jsx": false,
  "quote-props": "always",
  "semi": "always",
  "brace-style": "1tbs",
});

module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: "module",
  },
  env: {
    node: true,
    browser: true,
    jquery: true,
  },
  extends: [
    "eslint:recommended",
    // Allow linting of ERB files, see https://github.com/Splines/eslint-plugin-erb
    "plugin:erb/recommended",
  ],
  plugins: ["@stylistic", "erb"],
  rules: {
    ...customizedStylistic.rules,
    "no-unused-vars": "warn",
  },
};
