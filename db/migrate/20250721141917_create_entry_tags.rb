class CreateEntryTags < ActiveRecord::Migration[7.1]
  def change
    create_table :entry_tags do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :mood, null: false, foreign_key: true

      t.timestamps
    end
  end
end
