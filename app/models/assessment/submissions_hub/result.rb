module Assessment
  module SubmissionsHub
    # What one call to the loader hands back: every sheet of the lecture newest
    # first, the exam-admission standing, the sheets that can still be handed in
    # (soonest first), the subset of those sharing the next deadline, and the
    # sheet that came back most recently.
    Result = Struct.new(:sheets, :standing, :open_sheets, :due, :latest_marked,
                        keyword_init: true)
  end
end
