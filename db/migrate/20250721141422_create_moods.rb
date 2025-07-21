class CreateMoods < ActiveRecord::Migration[7.1]
  def change
    create_table :moods do |t|
      t.text :category

      t.timestamps
    end
  end
end
