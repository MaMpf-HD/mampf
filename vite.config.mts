import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
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
