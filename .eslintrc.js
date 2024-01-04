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
  "jsx": false,
  "quote-props": "always",
  "semi": "always",
  "brace-style": "1tbs",
});

const cypressRules = {
  "cypress/no-assigning-return-values": "error",
  "cypress/no-unnecessary-waiting": "off", // TODO: fix this issue
  "cypress/assertion-before-screenshot": "warn",
  "cypress/no-force": "warn",
  "cypress/no-async-tests": "error",
  "cypress/no-pause": "error",
};

const ignoreFilesWithSprocketRequireSyntax = [
  "app/assets/javascripts/application.js",
  "app/assets/config/manifest.js",
  "app/assets/javascripts/edit_clicker_assets.js",
  "app/assets/javascripts/show_clicker_assets.js",
  "app/assets/javascripts/geogebra_assets.js",
  "vendor/assets/javascripts/thredded_timeago.js",
];

const customGlobals = {
  TomSelect: "readable",
  bootstrap: "readable",

  // Rails globals
  Routes: "readable",
  App: "readable",
  ActionCable: "readable",

  // Common global methods
  initBootstrapPopovers: "readable",
};

module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: "module",
  },
  env: {
    "node": true,
    "browser": true,
    "jquery": true,
    "cypress/globals": true,
  },
  extends: [
    "eslint:recommended",
    // Allow linting of ERB files, see https://github.com/Splines/eslint-plugin-erb
    "plugin:erb/recommended",
  ],
  globals: customGlobals,
  plugins: ["@stylistic", "erb", "cypress"],
  rules: {
    ...customizedStylistic.rules,
    "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
    ...cypressRules,
    // see https://github.com/eslint-stylistic/eslint-stylistic/issues/254
    "@stylistic/quotes": ["error", "double", { avoidEscape: true }],
  },
  ignorePatterns: [
    "node_modules/",
    "pdfcomprezzor/",
    "tmp/",
    "public/packs/",
    "public/packs-test/",
    "public/uploads/",
    ...ignoreFilesWithSprocketRequireSyntax,
  ],
};
