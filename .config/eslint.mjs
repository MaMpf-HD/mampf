import eslint from "@eslint/js";
import html from "@html-eslint/eslint-plugin";
import htmlParser, { TEMPLATE_ENGINE_SYNTAX } from "@html-eslint/parser";
import stylistic from "@stylistic/eslint-plugin";
import erb from "eslint-plugin-erb";
import globals from "globals";
import tseslint from "typescript-eslint";

const ignoreFilesWithSprocketRequireSyntax = [
  "app/assets/config/manifest.js",
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

  mermaid: "readable",
};

export default tseslint.config(
  {
    // Globally ignore the following paths
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
      "spec/cypress/**",
      "architecture/src/js/mermaid.min.js",
    ],
  },
  {
    files: ["**/*.ts", "**/*.js"],
    plugins: {
      "@stylistic": stylistic,
    },
    extends: [
      eslint.configs.recommended,
      // Allow linting of ERB files, see https://github.com/Splines/eslint-plugin-erb
      erb.configs.recommended,
      tseslint.configs.recommendedTypeChecked,
      tseslint.configs.strictTypeChecked,
    ],
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
      // https://playwright.dev/docs/best-practices#lint-your-tests
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-explicit-any": "off",
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
      parserOptions: {
        // https://typescript-eslint.io/blog/project-service
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    linterOptions: {
      // see https://github.com/Splines/eslint-plugin-erb/releases/tag/v2.0.1
      reportUnusedDisableDirectives: "off",
    },
  },
  {
    // Disable type-checked linting
    // https://typescript-eslint.io/troubleshooting/typed-linting/#how-do-i-disable-type-checked-linting-for-a-file
    // https://typescript-eslint.io/troubleshooting/typed-linting/#i-get-errors-telling-me--was-not-found-by-the-project-service-consider-either-including-it-in-the-tsconfigjson-or-including-it-in-allowdefaultproject
    files: ["**/*.js", "**/*.mjs", "**/*.mts"],
    extends: [tseslint.configs.disableTypeChecked],
  },
  {
    // HTML linting
    files: ["**/*.html", "**/*.html.erb"],
    ...html.configs["flat/recommended"],
    plugins: {
      "@html-eslint": html,
      "@stylistic": stylistic,
    },
    // https://html-eslint.org/docs/integrating-template-engine
    languageOptions: {
      parser: htmlParser,
      parserOptions: {
        templateEngineSyntax: TEMPLATE_ENGINE_SYNTAX.ERB,
      },
    },
    rules: {
      "@stylistic/eol-last": ["error", "always"],
      "@stylistic/no-trailing-spaces": "error",
      "@stylistic/no-multiple-empty-lines": ["error", { max: 1, maxEOF: 0 }],
      ...html.configs["flat/recommended"].rules,
      // 🎈 Best Practices
      "@html-eslint/no-extra-spacing-text": "error",
      "@html-eslint/no-script-style-type": "error",
      "@html-eslint/no-target-blank": "error",
      // 🎈 Accessibility
      "@html-eslint/no-abstract-roles": "error",
      "@html-eslint/no-accesskey-attrs": "error",
      "@html-eslint/no-aria-hidden-body": "error",
      "@html-eslint/no-non-scalable-viewport": "error",
      "@html-eslint/no-positive-tabindex": "error",
      "@html-eslint/no-skip-heading-levels": "error",
      // 🎈 Styles
      "@html-eslint/attrs-newline": ["error", {
        closeStyle: "newline",
        ifAttrsMoreThan: 5,
      }],
      // activate once all other rules are in place (otherwise ESLint throws errors)
      // "@html-eslint/element-newline": "error",
      // something for the long run
      // "@html-eslint/id-naming-convention": ["error", "kebab-case"],
      "@html-eslint/indent": ["error", 2],
      "@html-eslint/sort-attrs": "error",
      "@html-eslint/no-extra-spacing-attrs": ["error", {
        enforceBeforeSelfClose: true,
        disallowMissing: true,
        disallowTabs: true,
        disallowInAssignment: true,
      }],
    },
  }
);
