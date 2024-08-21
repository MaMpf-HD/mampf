module VouchersHelper
  def tutorial_options(user, voucher)
    voucher.lecture.tutorials_without_tutor(user).map { |t| [t.title, t.id] }
  end

  def given_tutorial_ids(user, voucher)
    user.given_tutorials.where(lecture: voucher.lecture).pluck(:id)
  end

  def tutorials_with_tutor_titles(user, voucher)
    voucher.lecture.tutorials_with_tutor(user).map(&:title).join(", ")
  end

  def talks_with_titles(user, voucher)
    voucher.lecture.talks_with_speaker(user).map(&:to_label).join(", ")
  end

  def talk_options(user, voucher)
    voucher.lecture.talks_without_speaker(user)
           .map { |t| [t.to_label_with_speakers, t.id] }
  end

  def redeem_voucher_button(voucher)
    link_to(t("profile.redeem_voucher"),
            redeem_voucher_path(params: { secure_hash: voucher.secure_hash }),
            class: "btn btn-primary",
            data: { cy: "redeem-voucher-btn" },
            method: :post, remote: true)
  end

  def cancel_voucher_button
    link_to(t("buttons.cancel"), cancel_voucher_path,
            class: "btn btn-secondary ms-2", remote: true)
  end

  def claim_select_field(form, user, voucher)
    field_name, options, prompt = if voucher.tutor?
      [:tutorial_ids, tutorial_options(user, voucher), t("profile.select_tutorials")]
    elsif voucher.speaker?
      [:talk_ids, talk_options(user, voucher), t("profile.select_talks")]
    end

    form.select(field_name,
                options_for_select(options),
                { prompt: prompt },
                { multiple: true, class: "selectize me-2 w-50" })
  end
end
