# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb
puts "🧹 Cleaning database..."
EntryTag.destroy_all
JournalEntry.destroy_all
MoodSummary.destroy_all
Mood.destroy_all
User.destroy_all

puts "🎭 Creating moods..."
moods_data = [
  "happy", "sad", "anxious", "grateful", "excited", "calm",
  "frustrated", "content", "energetic", "peaceful", "confused",
  "motivated", "inspired", "nostalgic", "optimistic", "reflective",
  "loved", "lonely", "confident", "worried", "creative", "bored"
]

moods_data.each do |mood_category|
  Mood.create!(category: mood_category)
end

puts "👤 Creating sample user..."
user = User.create!(
  email: "demo@logsai.com",
  password: "password",
  name: "Demo",
  surname: "User"
)

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
    title: "Voice Note from Park",
    content: "Recorded some thoughts while walking in the park. Nature always helps me think clearly.",
    input_type: "speech",
    entry_date: Date.current - 2.days,
    moods: ["peaceful", "calm", "grateful"]
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
  entry = JournalEntry.create!(entry_data.merge(user: user))

  moods.each do |mood_name|
    mood = Mood.find_by(category: mood_name)
    EntryTag.create!(journal_entry: entry, mood: mood) if mood
  end
end

puts "📊 Creating sample mood summary..."
MoodSummary.create!(
  user: user,
  average_mood_summary: "Generally positive with some reflective moments",
  dominant_moods: "happy, energetic, grateful, reflective",
  entry_count: 4
)

puts "✅ Seeding completed!"
puts "📈 Created:"
puts "  - #{User.count} users"
puts "  - #{Mood.count} moods"
puts "  - #{JournalEntry.count} journal entries"
puts "  - #{EntryTag.count} mood tags"
puts "  - #{MoodSummary.count} mood summaries"
