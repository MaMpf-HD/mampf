class CertificationStaleCheckJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform(lecture_id)
    lecture = Lecture.find(lecture_id)

    StudentPerformance::ComputationService
      .new(lecture: lecture)
      .compute_and_upsert_all_records!

    stale = StudentPerformance::Certification
            .where(lecture: lecture)
            .stale

    return if stale.none?

    Rails.logger.info(
      "[CertificationStaleCheck] lecture_id=#{lecture_id} " \
      "stale_count=#{stale.count} " \
      "user_ids=#{stale.pluck(:user_id).join(",")}"
    )
  end
end
