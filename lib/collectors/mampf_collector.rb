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
    # appears in th log, which is not always the case when you start a quiz,
    # e. g. if you have already a
    # quiz open.
    consumptions_count_gauge = PrometheusExporter::Metric::Gauge.new("consumption_count",
                                                                     "number of consumptions")
    consumptions_count_gauge.observe(Consumption.count)

    # =================================================================
    # WORKER METRICS (CPU / RAM per Worker)
    # =================================================================

    puma_cpu_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_cpu_percent",
                                                           "CPU usage per Puma process")
    puma_ram_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_ram_mb",
                                                           "RAM usage per Puma process in MB")

    # 1. Get list of all processes (Master + Worker)
    process_stats = collect_detailed_puma_stats

    # 2. Loop through EACH Worker individually
    process_stats.each do |stat|
      # We attach labels: pid and role (master/worker)
      labels = { pid: stat[:pid], role: stat[:role] }

      puma_cpu_gauge.observe(stat[:cpu], labels)
      puma_ram_gauge.observe(stat[:ram], labels)
    end

    [
      user_count_gauge,
      medium_count_gauge,
      tag_count_gauge,
      submissions_count_gauge,
      lectures_count_gauge,
      consumptions_count_gauge,
      puma_cpu_gauge,
      puma_ram_gauge
    ]
  end

  private

    # The logic to find and read Master and Worker PIDs
    def collect_detailed_puma_stats
      stats = []
      pid_file = Rails.root.join("tmp/pids/server.pid")

      return stats unless File.exist?(pid_file)

      begin
        pid_content = File.read(pid_file).strip
        return stats if pid_content.empty?

        master_pid = pid_content.to_i

        # Find all CHILD processes (Worker) of the Master
        worker_pids_str = `pgrep -P #{master_pid} -d,`.strip

        # Build string of all PIDs (Master + Children) for the ps command
        all_pids = worker_pids_str.empty? ? master_pid.to_s : "#{master_pid},#{worker_pids_str}"

        # ps command: Returns PID, CPU and RAM (RSS)
        output = `ps -p #{all_pids} -o pid=,%cpu=,rss=`.strip

        unless output.empty?
          output.each_line do |line|
            parts = line.split
            next unless parts.length == 3

            current_pid = parts[0].to_i
            cpu = parts[1].to_f
            ram_mb = parts[2].to_f / 1024.0

            # Distinction: Is it the Master or a Worker?
            role = current_pid == master_pid ? "master" : "worker"

            stats << { pid: current_pid, role: role, cpu: cpu, ram: ram_mb }
          end
        end
      end

      stats
    end
end
