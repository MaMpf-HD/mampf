unless defined? Rails
    require File.expand_path("../../../config/environment", __FILE__)
end
class MampfCollector < PrometheusExporter::Server::TypeCollector
    def initialize
    end
  
    def collect(obj)
    end
    def type
        "mampf"
    end
  
    def metrics
        user_count_gauge = PrometheusExporter::Metric::Gauge.new('user_count', 'number of users in the app')
        user_count_gauge.observe User.count
        medium_count_gauge = PrometheusExporter::Metric::Gauge.new('uploaded_medium_count', 'number of media')
        medium_count_gauge.observe Medium.count
        tag_count_gauge = PrometheusExporter::Metric::Gauge.new('tag_count', 'number of tags')
        tag_count_gauge.observe Tag.count
        submissions_count_gauge = PrometheusExporter::Metric::Gauge.new('submissions_count', 'number of submissions')
        submissions_count_gauge.observe Submission.count
        [user_count_gauge, medium_count_gauge,tag_count_gauge, submissions_count_gauge]
      end
  end