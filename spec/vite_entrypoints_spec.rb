require "rails_helper"

# vite-plugin-ruby only recognises a fixed set of extensions as entrypoints.
# Anything else is copied verbatim into the production build and served with a
# MIME type the browser rejects for a module script — so the page silently
# breaks in production while working fine behind the dev server, which
# transpiles on the fly. This is what happened to js/geogebra.coffee.
RSpec.describe("Vite entrypoints") do
  # Mirrors KNOWN_ENTRYPOINT_TYPES of the vite-plugin-ruby release yarn.lock
  # pins (v5.2.2), where "jsx?" and "tsx?" are regex fragments. Re-check on
  # upgrade:
  # https://github.com/ElMassimo/vite_ruby/blob/3edc67485fd4021072b43ad3a073ffa0fa851ede/vite-plugin-ruby/src/constants.ts#L11-L28
  let(:transpilable_extensions) do
    ["html", "js", "jsx", "ts", "tsx",
     "css", "less", "sass", "scss", "styl", "stylus", "pcss", "postcss"]
  end

  it "never point at a file extension vite cannot transpile" do
    # Only the script/style helpers register entrypoints; vite_image_tag & co.
    # reference plain assets, which are served as-is and are fine. The call may
    # use parentheses and either quote style, and missing one of those forms
    # would leave a blind spot in this guard.
    helpers = /vite_(?:javascript|typescript|stylesheet)_tag/
    call = /#{helpers}\s*\(?\s*["']([^"']+)["']/

    offenders = Rails.root.glob("app/{views,frontend}/**/*.erb").flat_map do |path|
      entrypoints = path.read.scan(call).flatten

      entrypoints.filter_map do |entrypoint|
        extension = File.extname(entrypoint).delete_prefix(".")
        next if extension.empty? || transpilable_extensions.include?(extension)

        "#{path.relative_path_from(Rails.root)}: #{entrypoint}"
      end
    end

    expect(offenders).to be_empty
  end
end
