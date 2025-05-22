# Ruby instrumentation framework

# ▶ Configure PID provider for more performant metrics
# https://gitlab.com/gitlab-org/ruby/gems/prometheus-client-mmap#pid-cardinality
# https://dev.37signals.com/kamal-prometheus/
require "prometheus/client/support/puma"
Prometheus::Client.configuration.pid_provider =
  Prometheus::Client::Support::Puma.method(:worker_pid_provider)

# https://github.com/yabeda-rb/yabeda-prometheus?tab=readme-ov-file#multi-process-server-support
