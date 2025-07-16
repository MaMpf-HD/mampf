// Starting with v9, this config will be deprecated in favor of the new
// configuration files [1]. @stylistic is already ready for the new "flat config",
// when it's time, copy the new config from [2].
// [1] https://eslint.org/docs/latest/use/configure/configuration-files-new
// [2] https://eslint.style/guide/config-presets#configuration-factory

// Stylistic Plugin for ESLint
// see the rules in [3] and [4].
// [3] https://eslint.style/packages/js#rules
// [4] https://eslint.org/docs/rules/
import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";
import pluginCypress from "eslint-plugin-cypress/flat";
import erb from "eslint-plugin-erb";
import globals from "globals";

const ignoreFilesWithSprocketRequireSyntax = [
  "app/assets/javascripts/application.js",
  "app/assets/config/manifest.js",
  "app/assets/javascripts/edit_clicker_assets.js",
  "app/assets/javascripts/show_clicker_assets.js",
  "app/assets/javascripts/geogebra_assets.js",
  "vendor/assets/javascripts/thredded_timeago.js",
];

const ignoreCypressArchivedTests = [
  "spec/cypress/e2e/admin_spec.cy.archive.js",
  "spec/cypress/e2e/courses_spec.cy.archive.js",
  "spec/cypress/e2e/media_spec.cy.archive.js",
  "spec/cypress/e2e/search_spec.cy.archive.js",
  "spec/cypress/e2e/submissions_spec.cy.archive.js",
  "spec/cypress/e2e/thredded_spec.cy.archive.js",
  "spec/cypress/e2e/tutorials_spec.cy.archive.js",
  "spec/cypress/e2e/watchlists_spec.cy.archive.js",
];

const customGlobals = {
  TomSelect: "readable",
  bootstrap: "readable",

  // Rails globals
  Routes: "readable",
  App: "readable",
  ActionCable: "readable",
  ActiveStorage: "readable",

  thymeAttributes: "readable",

  // Common global methods
  initBootstrapPopovers: "readable",

  // KaTeX
  renderMathInElement: "readable",

  Sortable: "readable",

  fillOptionsByAjax: "readable",
  previewTrixTalkContent: "readable",
};

export default [
  js.configs.recommended,
  // Allow linting of ERB files, see https://github.com/Splines/eslint-plugin-erb
  erb.configs.recommended,
  pluginCypress.configs.recommended,
  // Globally ignore the following paths
  {
    ignores: [
      "node_modules/",
      "pdfcomprezzor/",
      "tmp/",
      "public/packs/",
      "public/packs-test/",
      "public/uploads/",
      "public/pdfcomprezzor/",
      ...ignoreFilesWithSprocketRequireSyntax,
      ...ignoreCypressArchivedTests,
    ],
  },
  {
    plugins: {
      "@stylistic": stylistic,
    },
    rules: {
      ...stylistic.configs.customize({
        "indent": 2,
        "jsx": false,
        "quote-props": "always",
        "semi": true,
        "brace-style": "1tbs",
      }).rules,
      "@stylistic/quotes": ["error", "double", { avoidEscape: true }],
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
    },
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...customGlobals,
        ...globals.browser,
        ...globals.jquery,
        ...globals.node,
      },
    },
    linterOptions: {
      // see https://github.com/Splines/eslint-plugin-erb/releases/tag/v2.0.1
      reportUnusedDisableDirectives: "off",
    },
  },
];
