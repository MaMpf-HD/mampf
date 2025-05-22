# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

# https://github.com/yabeda-rb/yabeda-prometheus-mmap
require "yabeda/prometheus/mmap"
use Yabeda::Prometheus::Exporter

run Rails.application
Rails.application.load_server
