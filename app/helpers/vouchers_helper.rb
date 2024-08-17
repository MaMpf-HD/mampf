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
end
