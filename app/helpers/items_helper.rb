# Items helper module
module ItemsHelper
  # returns the list of sections for the given item,
  # as is used in options_for_select
  def select_sections(item)
    [[I18n.t("admin.item.no_section"), ""]] +
      item.medium.teachable&.section_selection
  end

  # returns the list of script_items for the given item,
  # as is used in options_for_select
  def select_script_items(lecture)
    lecture.script_items_by_position.map do |i|
      [i.title_within_lecture, i.pdf_destination]
    end
  end

  def check_unless_hidden(item_id)
    return "checked" unless Item.find_by(id: item_id)&.hidden

    ""
  end

  def check_status(content)
    content["hidden"] ? "" : "checked "
  end
end
