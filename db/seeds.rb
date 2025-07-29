# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting seed process..."

# Only destroy in development/test - be safe in production
if Rails.env.development? || Rails.env.test? || ENV['FORCE_SEED_RESET'] == 'true'
  puts "🧹 Cleaning database (safe order)..."
  # Order matters for foreign key constraints
  EntryTag.destroy_all
  JournalEntry.destroy_all
  MoodSummary.destroy_all
  Mood.destroy_all
  User.destroy_all
else
  puts "🔒 Production mode - skipping data cleanup (use FORCE_SEED_RESET=true to override)"
end

puts "🎭 Creating moods..."
moods_data = [
  "happy", "sad", "anxious", "grateful", "excited", "calm",
  "frustrated", "content", "energetic", "peaceful", "confused",
  "motivated", "inspired", "nostalgic", "optimistic", "reflective",
  "loved", "lonely", "confident", "worried", "creative", "bored"
]

moods_data.each do |mood_category|
  Mood.find_or_create_by!(category: mood_category)
end

puts "👤 Creating sample user..."
user = User.find_or_create_by!(email: "demo@logsai.com") do |u|
  u.password = "password"
  u.name = "Demo"
  u.surname = "User"
end

puts "📔 Creating sample journal entries..."
sample_entries = [
  {
    title: "Great Morning Workout",
    content: "Had an amazing workout this morning. Feeling energized and ready for the day!",
    input_type: "text",
    entry_date: Date.current,
    moods: ["energetic", "happy", "motivated"]
  },
  {
    title: "Reflecting on Yesterday",
    content: "Yesterday was a bit challenging, but I learned a lot about myself.",
    input_type: "text",
    entry_date: Date.current - 1.day,
    moods: ["reflective", "grateful"]
  },
  {
    title: "Quick Check-in",
    content: "Just a quick note about my day. Nothing special, but wanted to maintain the habit.",
    input_type: "text",
    entry_date: Date.current - 3.days,
    moods: ["content"]
  }
]

sample_entries.each do |entry_data|
  moods = entry_data.delete(:moods)

  # Check if entry already exists to avoid duplicates
  entry = JournalEntry.find_or_create_by!(
    title: entry_data[:title],
    user: user
  ) do |e|
    e.content = entry_data[:content]
    e.input_type = entry_data[:input_type]
    e.entry_date = entry_data[:entry_date]
  end

  # Add mood tags if they don't already exist
  moods.each do |mood_name|
    mood = Mood.find_by(category: mood_name)
    if mood && !EntryTag.exists?(journal_entry: entry, mood: mood)
      EntryTag.create!(journal_entry: entry, mood: mood)
    end
  end
end

puts "📊 Creating sample mood summary..."
MoodSummary.find_or_create_by!(user: user) do |summary|
  summary.average_mood_summary = "Generally positive with some reflective moments"
  summary.dominant_moods = "happy, energetic, grateful, reflective"
  summary.entry_count = user.journal_entries.count
end

puts "✅ Seeding completed!"
puts "📈 Database stats:"
puts "  - #{User.count} users"
puts "  - #{Mood.count} moods"
puts "  - #{JournalEntry.count} journal entries"
puts "  - #{EntryTag.count} mood tags"
puts "  - #{MoodSummary.count} mood summaries"
