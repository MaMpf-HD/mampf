class PerformanceRecordUpdateJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  def perform(lecture_id, user_id = nil)
    lecture = with_writing_role { Lecture.find_by(id: lecture_id) }

    unless lecture
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find Lecture with 'id'=#{lecture_id}")
    end

    service = StudentPerformance::ComputationService.new(lecture: lecture)

    if user_id
      user = User.find(user_id)
      service.compute_and_upsert_record_for(user)
    else
      service.compute_and_upsert_all_records!
    end
  end

  private

    def with_writing_role(&)
      ActiveRecord::Base.connected_to(role: :writing, &)
    end
end
