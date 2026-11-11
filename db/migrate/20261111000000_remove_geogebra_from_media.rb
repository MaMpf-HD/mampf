# MaMpf no longer offers GeoGebra applets. The few media that carried one go
# entirely, then the columns. Medium no longer knows the applet attachment,
# so its files (the .ggb and the screenshot derived from it) are deleted from
# the store directly, once the database changes stand.
#
# Uses the Medium model on purpose: destroying a medium takes its items, tags,
# comments, quiz vertices and other files along, which plain SQL would miss.
# On a fresh database there are no such media and the loop does nothing.
class RemoveGeogebraFromMedia < ActiveRecord::Migration[8.0]
  def up
    Medium.reset_column_information
    applet_files = []

    Medium.where.not(geogebra_data: nil).find_each do |medium|
      say("Deleting medium #{medium.id} (#{medium.sort}): #{medium.description}")
      applet_files << medium.geogebra_data
      Annotation.where(medium_id: medium.id).delete_all
      Link.where(linked_medium_id: medium.id).delete_all
      # The assignment stays; it only loses the medium it pointed to.
      # rubocop:disable Rails/SkipsModelValidations
      Assignment.where(medium_id: medium.id).update_all(medium_id: nil)
      # rubocop:enable Rails/SkipsModelValidations
      medium.destroy!
    end

    remove_column :media, :geogebra_data
    remove_column :media, :geogebra_app_name
    Medium.reset_column_information

    applet_files.each { |data| delete_stored_files(data) }
  end

  def down
    add_column :media, :geogebra_data, :text
    add_column :media, :geogebra_app_name, :text
  end

  private

    def delete_stored_files(data)
      file = JSON.parse(data)
      [file, *file.fetch("derivatives", {}).values].each do |stored|
        Shrine.storages.fetch(stored["storage"].to_sym).delete(stored["id"])
      end
    end
end
