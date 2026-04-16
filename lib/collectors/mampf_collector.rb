require File.expand_path("../../config/environment", __dir__) unless defined? Rails
require "prometheus_exporter/server"

class MampfCollector < PrometheusExporter::Server::TypeCollector
  def collect(obj)
  end

  def type
    "mampf"
  end

  def metrics
    # =================================================================
    # GLOBAL METRICS (Database)
    # =================================================================

    # User count
    user_count_gauge = PrometheusExporter::Metric::Gauge.new("user_count",
                                                             "number of users in the app")
    user_count_gauge.observe(User.count)

    # Medium count
    medium_count_gauge = PrometheusExporter::Metric::Gauge.new("uploaded_medium_count",
                                                               "number of media")
    medium_count_gauge.observe(Medium.count)

    # Tag count
    tag_count_gauge = PrometheusExporter::Metric::Gauge.new("tag_count",
                                                            "number of tags")
    tag_count_gauge.observe(Tag.count)

    # Submissions count
    submissions_count_gauge = PrometheusExporter::Metric::Gauge.new("submissions_count",
                                                                    "number of submissions")
    submissions_count_gauge.observe(Submission.count)

    # Lectures count
    lectures_count_gauge = PrometheusExporter::Metric::Gauge.new("lecture_count",
                                                                 "number of lectures")
    lectures_count_gauge.observe(Lecture.count)

    # Consumptions count
    #
    # only counts when TRANSACTION BEGIN /*application='Mampf'*/ with INSERT INTO "consumptions"
    # appears in the log, which is not always the case when you start a quiz,
    # e. g. if you have already a
    # quiz open.
    consumptions_count_gauge = PrometheusExporter::Metric::Gauge.new("consumption_count",
                                                                     "number of consumptions")
    consumptions_count_gauge.observe(Consumption.count)

    # =================================================================
    # NETWORK METRICS (Bytes In/Out from OS)
    # =================================================================

    # Does not end with _total to avoid Prometheus metric naming errors
    net_rx_gauge = PrometheusExporter::Metric::Gauge.new("mampf_app_network_receive_bytes",
                                                         "Cumulative bytes received")

    net_tx_gauge = PrometheusExporter::Metric::Gauge.new("mampf_app_network_transmit_bytes",
                                                         "Cumulative bytes transmitted")

    net_stats = collect_network_stats
    if net_stats
      labels = { interface: net_stats[:interface] }
      net_rx_gauge.observe(net_stats[:rx], labels)
      net_tx_gauge.observe(net_stats[:tx], labels)
    end

    # =================================================================
    # WORKER METRICS (CPU / RAM per Worker)
    # =================================================================

    puma_cpu_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_cpu_percent",
                                                           "CPU usage per Puma process")
    puma_ram_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_ram_mb",
                                                           "RAM usage per Puma process in MB")
    puma_ram_pct_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_ram_percent",
                                                               "RAM usage per Puma process in %")

    # 1. Get list of all processes (Master + Worker)
    process_stats = collect_detailed_puma_stats

    # 2. Loop through EACH Worker individually
    process_stats.each do |stat|
      # We attach labels: pid and role (master/worker)
      labels = { pid: stat[:pid], role: stat[:role] }

      puma_cpu_gauge.observe(stat[:cpu], labels)
      puma_ram_gauge.observe(stat[:ram], labels)
      puma_ram_pct_gauge.observe(stat[:ram_pct], labels)
    end

    [
      user_count_gauge,
      medium_count_gauge,
      tag_count_gauge,
      submissions_count_gauge,
      lectures_count_gauge,
      consumptions_count_gauge,
      net_rx_gauge,
      net_tx_gauge,
      puma_cpu_gauge,
      puma_ram_gauge,
      puma_ram_pct_gauge
    ]
  end

  private

    def collect_network_stats
      return nil unless File.exist?("/proc/net/dev")

      File.readlines("/proc/net/dev").each do |line|
        next unless line.include?(":")

        parts = line.split(":")
        interface = parts[0].strip

        # Filter to eth0, ignoring loopback (lo) or tunnel interfaces
        next unless interface == "eth0"

        values = parts[1].split
        # Index 0 = Receive Bytes, Index 8 = Transmit Bytes
        return {
          interface: interface,
          rx: values[0].to_i,
          tx: values[8].to_i
        }
      end
      nil
    end

    def collect_detailed_puma_stats
      stats = []
      pid_file = Rails.root.join("tmp/pids/server.pid")

      return stats unless File.exist?(pid_file)

      pid_content = File.read(pid_file).strip
      return stats if pid_content.empty?

      master_pid = pid_content.to_i

      # Find all CHILD processes (Worker) of the Master
      worker_pids_str = `pgrep -P #{master_pid} -d,`.strip

      # Build string of all PIDs (Master + Children) for the ps command
      all_pids = worker_pids_str.empty? ? master_pid.to_s : "#{master_pid},#{worker_pids_str}"

      # ps command: Returns PID, CPU, RAM (RSS) and COMMAND
      output = `ps -p #{all_pids} -o pid=,%cpu=,rss=,%mem=,comm=`.strip

      worker_count = 1

      unless output.empty?
        output.each_line do |line|
          parts = line.split
          next unless parts.length >= 5

          current_pid = parts[0].to_i
          # 'tee' processes are not connected to Puma workers
          #  and exclusively exist to pass on metrics
          next if parts[4] == "tee"

          cpu = parts[1].to_f
          ram_mb = parts[2].to_f / 1024.0
          ram_percent = parts[3].to_f

          # Distinction: Is it the Master or a Worker?
          if current_pid == master_pid
            role = "master"
          else
            role = "worker#{worker_count}"
            worker_count += 1
          end

          stats << { pid: current_pid, role: role, cpu: cpu, ram: ram_mb, ram_pct: ram_percent }
        end
      end

      stats
    end
end
