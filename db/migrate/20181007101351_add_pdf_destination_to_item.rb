class AddPdfDestinationToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :pdf_destination, :text
  end
end
