class CreateJournalEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :journal_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :input_type
      t.date :entry_date

      t.timestamps
    end
  end
end
