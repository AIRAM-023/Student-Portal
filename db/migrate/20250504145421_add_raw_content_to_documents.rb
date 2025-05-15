class AddRawContentToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :raw_content, :text
  end
end
