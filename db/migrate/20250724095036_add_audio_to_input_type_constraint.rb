class AddAudioToInputTypeConstraint < ActiveRecord::Migration[7.1]
  def up
    # First, fix any existing invalid data
    execute "UPDATE journal_entries SET input_type = 'text' WHERE input_type NOT IN ('text', 'image', 'video')"

    # Remove the old constraint
    execute "ALTER TABLE journal_entries DROP CONSTRAINT IF EXISTS valid_input_type"

    # Add new constraint that includes 'audio'
    execute "ALTER TABLE journal_entries ADD CONSTRAINT valid_input_type CHECK (input_type IN ('text', 'image', 'video', 'audio'))"
  end

  def down
    # Remove the constraint with audio
    execute "ALTER TABLE journal_entries DROP CONSTRAINT IF EXISTS valid_input_type"

    # Add back the old constraint (without audio)
    execute "ALTER TABLE journal_entries ADD CONSTRAINT valid_input_type CHECK (input_type IN ('text', 'image', 'video'))"
  end
end
