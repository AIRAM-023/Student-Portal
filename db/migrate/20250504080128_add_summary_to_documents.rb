class AddSummaryToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :summary, :text
  end
end
