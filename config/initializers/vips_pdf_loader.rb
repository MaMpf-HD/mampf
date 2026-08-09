# Active Storage blocks libvips' unfuzzed loaders since Rails 8.0.5.1, which takes the
# PDF loader with it and 500s every manuscript upload. Re-enabling it accepts
# CVE-2025-59933, unfixed in trixie's libvips. Delete this file at libvips 8.17.2+.
Vips.block("VipsForeignLoadPdf", false) if defined?(Vips)
