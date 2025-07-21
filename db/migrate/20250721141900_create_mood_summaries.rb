class CreateMoodSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :mood_summaries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :average_mood_summary
      t.string :dominant_moods
      t.integer :entry_count

      t.timestamps
    end
  end
end
