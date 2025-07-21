class AddConstraints < ActiveRecord::Migration[7.1]
  def change
    # This prevents bad data even if Rails validations fail
    add_check_constraint :journal_entries,
      "input_type IN ('text', 'speech', 'image') OR input_type IS NULL",
      name: "valid_input_type"
  end
end
