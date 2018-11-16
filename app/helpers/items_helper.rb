# Items helper module
module ItemsHelper
  # returns the list of manuscript and pdf destinations for the given item,
  # as is used in options_for_select
  def select_destinations(item)
    [['auswählen (setzt Seitenauswahl außer Kraft)', '']] +
      (item.medium.manuscript_destinations | [item.pdf_destination])
      .map { |d| [d, d] }
  end

  # returns the list of sections for the given item,
  # as is used in options_for_select
  def select_sections(item)
    [['kein zugeordneter Abschnitt aus der Datenbank', '']] +
      item.medium.teachable.section_selection
  end
end
