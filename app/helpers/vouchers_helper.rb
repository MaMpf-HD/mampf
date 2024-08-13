module VouchersHelper
  def tutorial_options(voucher)
    voucher.lecture.tutorials.map { |t| [t.title, t.id] }
  end

  def given_tutorial_ids(user, voucher)
    user.given_tutorials.where(lecture: voucher.lecture).pluck(:id)
  end
end
