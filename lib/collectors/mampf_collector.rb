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
    # GLOBALE METRIKEN (Datenbank)
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
    # TEIL 2: WORKER METRIKEN (CPU / RAM pro Worker)
    # =================================================================

    puma_cpu_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_cpu_percent",
                                                           "CPU usage per Puma process")
    puma_ram_gauge = PrometheusExporter::Metric::Gauge.new("puma_process_ram_mb",
                                                           "RAM usage per Puma process in MB")

    # 1. Hole Liste aller Prozesse (Master + Worker)
    process_stats = get_detailed_puma_stats

    # 2. Schleife durch JEDEN Worker einzeln
    process_stats.each do |stat|
      # Wir hängen Labels an: pid und role (master/worker)
      labels = { pid: stat[:pid], role: stat[:role] }

      puma_cpu_gauge.observe(stat[:cpu], labels)
      puma_ram_gauge.observe(stat[:ram], labels)
    end

    # =================================================================
    # RÜCKGABE: Wir kombinieren beide Listen
    # =================================================================
    [
      user_count_gauge,
      medium_count_gauge,
      tag_count_gauge,
      submissions_count_gauge,
      lectures_count_gauge,
      consumptions_count_gauge,
      puma_cpu_gauge,  # Enthält jetzt Daten für ALLE Worker (mit Labels)
      puma_ram_gauge   # Enthält jetzt Daten für ALLE Worker (mit Labels)
    ]
  end

  private

    # Die Logik, um Master und Worker PIDs zu finden und auszulesen
    def get_detailed_puma_stats
      stats = []
      pid_file = Rails.root.join("tmp/pids/server.pid")

      return stats unless File.exist?(pid_file)

      begin
        pid_content = File.read(pid_file).strip
        return stats if pid_content.empty?

        master_pid = pid_content.to_i

        # Finde alle KIND-Prozesse (Worker) des Masters
        worker_pids_str = `pgrep -P #{master_pid} -d,`.strip

        # Baue String aller PIDs (Master + Kinder) für den ps Befehl
        all_pids = worker_pids_str.empty? ? master_pid.to_s : "#{master_pid},#{worker_pids_str}"

        # ps Befehl: Gibt PID, CPU und RAM (RSS) zurück
        output = `ps -p #{all_pids} -o pid=,%cpu=,rss=`.strip

        unless output.empty?
          output.each_line do |line|
            parts = line.split(" ")
            next unless parts.length == 3 

            current_pid = parts[0].to_i
            cpu = parts[1].to_f
            ram_mb = parts[2].to_f / 1024.0

            # Unterscheidung: Ist es der Master oder ein Worker?
            role = current_pid == master_pid ? "master" : "worker"

            stats << { pid: current_pid, role: role, cpu: cpu, ram: ram_mb }
          end
        end
      rescue StandardError => e
        # Fehler ignorieren (z.B. Prozess stirbt während Abfrage)
      end

      stats
    end
end
