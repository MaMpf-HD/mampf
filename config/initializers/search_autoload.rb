# Define the root namespace
module Search; end

# Tell Zeitwerk to watch app/search as the Search namespace
Rails.autoloaders.main.push_dir(
  Rails.root.join("app/search"),
  namespace: Search
)
