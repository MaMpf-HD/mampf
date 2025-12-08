require File.expand_path("../../config/environment", __dir__) unless defined? Rails
class MampfCollector < PrometheusExporter::Server::TypeCollector
  def collect(obj)
  end

  def type
    "mampf"
  end

  def metrics
    user_count_gauge = PrometheusExporter::Metric::Gauge.new("user_count",
                                                             "number of users in the app")
    user_count_gauge.observe(User.count)

    medium_count_gauge = PrometheusExporter::Metric::Gauge.new("uploaded_medium_count",
                                                               "number of media")
    medium_count_gauge.observe(Medium.count)

    tag_count_gauge = PrometheusExporter::Metric::Gauge.new("tag_count", "number of tags")
    tag_count_gauge.observe(Tag.count)

    submissions_count_gauge = PrometheusExporter::Metric::Gauge.new("submissions_count",
                                                                    "number of submissions")
    submissions_count_gauge.observe(Submission.count)

    # lectures count
    lectures_count_gauge = PrometheusExporter::Metric::Gauge.new("lecture_count",
                                                                 "number of lectures")
    lectures_count_gauge.observe(Lecture.count)

    # consumptions count
    #
    # only counts when TRANSACTION BEGIN /*application='Mampf'*/ with INSERT INTO "consumptions"
    # appers in th log, which is not always the case when you start a quize if you have already a
    # quiz open.
    consumptions_count_gauge = PrometheusExporter::Metric::Gauge.new("consumption_count",
                                                                     "number of consumptions")
    consumptions_count_gauge.observe(Consumption.count)

    [user_count_gauge,
     medium_count_gauge,
     tag_count_gauge,
     submissions_count_gauge,
     lectures_count_gauge,
     consumptions_count_gauge]
  end
end
