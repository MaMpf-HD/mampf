require "rails_helper"

# vite-plugin-ruby only recognises a fixed set of extensions as entrypoints.
# Anything else is copied verbatim into the production build and served with a
# MIME type the browser rejects for a module script — so the page silently
# breaks in production while working fine behind the dev server, which
# transpiles on the fly. This is what happened to js/geogebra.coffee.
RSpec.describe("Vite entrypoints") do
  let(:transpilable_extensions) do
    ["js", "mjs", "jsx", "ts", "tsx", "css", "scss", "sass", "less", "styl", "stylus", "pcss",
     "postcss"]
  end

  it "never point at a file extension vite cannot transpile" do
    # only the script/style helpers register entrypoints; vite_image_tag & co.
    # reference plain assets, which are served as-is and are fine.
    helpers = /vite_(?:javascript|typescript|stylesheet)_tag/

    offenders = Rails.root.glob("app/{views,frontend}/**/*.erb").flat_map do |path|
      entrypoints = path.read.scan(/#{helpers}\s+"([^"]+)"/).flatten

      entrypoints.filter_map do |entrypoint|
        extension = File.extname(entrypoint).delete_prefix(".")
        next if extension.empty? || transpilable_extensions.include?(extension)

        "#{path.relative_path_from(Rails.root)}: #{entrypoint}"
      end
    end

    expect(offenders).to be_empty
  end
end
