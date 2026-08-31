module Assessment
  module SubmissionsHub
    # What one call to the loader hands back: every sheet of the lecture newest
    # first, the exam-admission standing, the sheets whose deadline is next up
    # (a lecture may set more than one for the same date), and the sheet that came
    # back most recently.
    Result = Struct.new(:sheets, :standing, :due, :latest_marked,
                        keyword_init: true)
  end
end
