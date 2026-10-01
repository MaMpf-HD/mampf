# Formats a person's account state and personal data for the support pages.
module SupportUsersHelper
  # Lists a person the way exam lists do: last name first.
  def listed_name(user)
    [user.last_name, user.first_name].compact.join(", ").presence || user.name
  end

  def confirmation_status(user)
    status = if user.confirmed?
      t("support.users.status.confirmed_at", time: l(user.confirmed_at, format: :short))
    else
      t("support.users.status.unconfirmed", time: l(user.created_at, format: :short))
    end
    return status unless user.pending_reconfirmation?

    "#{status} #{t("support.users.status.new_email_pending", email: user.unconfirmed_email)}"
  end

  # Devise lifts a lock by itself after User.unlock_in, so the time says when.
  def lock_status(user)
    if user.access_locked?
      t("support.users.status.locked_until",
        time: l(user.locked_at + User.unlock_in, format: :short),
        attempts: user.failed_attempts)
    else
      t("support.users.status.not_locked", count: user.failed_attempts)
    end
  end

  # Devise keeps the latest sign-in in current_sign_in_at; last_sign_in_at is
  # the one before.
  def sign_in_status(user)
    return t("support.users.status.never_signed_in") unless user.current_sign_in_at

    t("support.users.status.signed_in", time: l(user.current_sign_in_at, format: :short),
                                        count: user.sign_in_count)
  end

  def personal_data_status(user)
    if user.personal_data_confirmed_at
      t("support.users.status.personal_data_confirmed",
        time: l(user.personal_data_confirmed_at, format: :short))
    elsif user.personal_data_declined?
      t("support.users.status.personal_data_declined")
    else
      t("support.users.status.personal_data_open")
    end
  end

  # The programs students pick from, and the person's own even if it is no
  # longer offered, so that saving does not drop it.
  def support_program_options(user)
    programs = (study_programs + [user.program]).compact.uniq
    programs.map { |program| [program.name_with_subject, program.id] }
  end
end
