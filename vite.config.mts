import inject from "@rollup/plugin-inject";
import { defineConfig } from 'vite';
import { coffee } from "vite-plugin-coffee3";
import RubyPlugin from 'vite-plugin-ruby';

// also see config/vite.rb
const gemPaths = JSON.parse(process.env.GEM_PATHS || '[]');

export default defineConfig({
  plugins: [
    coffee(),
    inject({
      jQuery: "jquery",
      include: ["**/*.js", "**/*.ts", "**/*.coffee"],
    }),
    RubyPlugin(),
  ],

  resolve: {
    alias: gemPaths,
  },

  server: {
    fs: {
      allow: Object.values(gemPaths),
    }
  },

  // TODO (keep track).
  // Bootstrap: Silence Sass deprecation warnings.
  // See https://getbootstrap.com/docs/5.3/getting-started/vite/#configure-vite
  // and https://github.com/twbs/bootstrap/issues/40962
  // https://github.com/sass/dart-sass/issues/2352#issuecomment-2856939940
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: [
          "legacy-js-api",
          "import",
          "mixed-decls",
          "color-functions",
          "global-builtin",
        ],
      },
    },
  },
});
