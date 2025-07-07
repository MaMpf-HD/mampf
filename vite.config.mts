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

  // Bootstrap: Silence Sass deprecation warnings.
  // See https://getbootstrap.com/docs/5.3/getting-started/vite/#configure-vite
  // and https://github.com/twbs/bootstrap/issues/40962
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: [
          "import",
          "mixed-decls",
          "color-functions",
          "global-builtin",
        ],
      },
    },
  },
});
