require File.expand_path("../../config/environment", __dir__) unless defined? Rails
class MampfCollector < PrometheusExporter::Server::TypeCollector
  def initialize # rubocop:todo Lint/MissingSuper
  end

  def collect(obj)
  end

  def type
    "mampf"
  end

  def metrics
    user_count_gauge = PrometheusExporter::Metric::Gauge.new("user_count",
                                                             "number of users in the app")
      user_count_gauge.observe User.count # rubocop:todo Layout/IndentationConsistency
      # rubocop:todo Layout/IndentationConsistency
      medium_count_gauge = PrometheusExporter::Metric::Gauge.new("uploaded_medium_count",
                                                                 "number of media")
      # rubocop:enable Layout/IndentationConsistency
      medium_count_gauge.observe Medium.count # rubocop:todo Layout/IndentationConsistency
      # rubocop:todo Layout/IndentationConsistency
      tag_count_gauge = PrometheusExporter::Metric::Gauge.new("tag_count", "number of tags")
      # rubocop:enable Layout/IndentationConsistency
      tag_count_gauge.observe Tag.count # rubocop:todo Layout/IndentationConsistency
      # rubocop:todo Layout/IndentationConsistency
      submissions_count_gauge = PrometheusExporter::Metric::Gauge.new("submissions_count",
                                                                      "number of submissions")
      # rubocop:enable Layout/IndentationConsistency
      # rubocop:todo Layout/IndentationConsistency
      submissions_count_gauge.observe Submission.count
      # rubocop:enable Layout/IndentationConsistency
      # rubocop:todo Layout/IndentationConsistency
      [user_count_gauge, medium_count_gauge, tag_count_gauge, submissions_count_gauge]
    # rubocop:enable Layout/IndentationConsistency
  end
end
