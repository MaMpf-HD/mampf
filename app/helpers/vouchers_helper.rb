module VouchersHelper
  def tutorial_options(user, voucher)
    voucher.lecture.tutorials_open_to(user).map { |t| [t.title, t.id] }
  end

  def given_tutorial_ids(user, voucher)
    user.given_tutorials.where(lecture: voucher.lecture).pluck(:id)
  end

  def tutorials_with_tutor_titles(user, voucher)
    voucher.lecture.tutorials_with_tutor(user).map(&:title).join(", ")
  end

  def redeem_voucher_button(voucher)
    link_to(t("profile.redeem_voucher"),
            redeem_voucher_path(params: { secure_hash: voucher.secure_hash }),
            class: "btn btn-primary",
            method: :post, remote: true)
  end

  def cancel_voucher_button
    link_to(t("buttons.cancel"), cancel_voucher_path,
            class: "btn btn-secondary ms-2", remote: true)
  end

  def claim_select_field(form, user, voucher)
    form.select(:tutorial_ids,
                options_for_select(tutorial_options(user, voucher)),
                { prompt: t("profile.select_tutorials") },
                { multiple: true, class: "selectize me-2", style: "width: 20rem" })
  end
end
