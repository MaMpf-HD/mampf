# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and
# filtered from the log file. Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # What a lecturer or tutor writes to their students is theirs, not the log's.
  "student_message.subject", "student_message.body",
  :first_name, :last_name, :matriculation_number, :uni_id, :program_id,
  # A student's points, grades and the notes on them, and whom staff look
  # for. Whole keys only: a partial "grade" would also hide grading_scope_type.
  /\A(grade|comment|note|task_points|submissions|participations|q)\z/,
  "support_request.message", "user.name", :name_in_tutorials,
  # A search is a GET: the logged path carries search%5Bfulltext%5D, which a
  # nested "search.fulltext" would not match.
  :fulltext
]

# Request parameter filters do not apply to Active Job arguments, which
# include mail recipients and support messages.
ActiveSupport.on_load(:active_job) { self.log_arguments = false }
