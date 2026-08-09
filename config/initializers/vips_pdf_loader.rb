# Active Storage blocks libvips' unfuzzed loaders since Rails 8.0.5.1. MaMpf renders
# a preview image from every uploaded manuscript, so the PDF loader has to come back.
Vips.block("VipsForeignLoadPdf", false) if defined?(Vips)
