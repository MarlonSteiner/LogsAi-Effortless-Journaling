# app/services/mood_analysis_service.rb
class MoodAnalysisService
  def initialize(journal_entry)
    @journal_entry = journal_entry
    @client = OpenAI::Client.new
  end

  def analyze
    return nil unless @journal_entry.content.present?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: <<~PROMPT
              You are an expert mood analyst and emotional intelligence coach. Analyze this journal entry with deep insight and empathy.

              Analyze the entire emotional landscape - explicit feelings, underlying tones, life circumstances, and emotional progression throughout the entry.

              Provide:
              1. A precise mood label that captures the dominant emotional tone. Consider nuanced emotions like: contemplative, nostalgic, determined, conflicted, hopeful, overwhelmed, peaceful, inspired, melancholic, optimistic, anxious, grateful, frustrated, content, excited, joyful, sad, angry, etc.

              2. A polished, well-written 2-3 sentence summary that captures the essence of the entry while preserving the emotional tone.

              3. A CSS color value that matches the emotion (like '#4a90e2' for calm or '#e74c3c' for stressed).

              4. A subtle CSS background style that matches the emotion.

              Respond ONLY in this exact JSON format:
              {
                "mood_label": "precise_emotion",
                "summary": "polished summary here",
                "color_theme": "#hexcolor",
                "background_style": "css background style"
              }
            PROMPT
          },
          {
            role: "user",
            content: @journal_entry.content
          }
        ]
      }
    )

    # Extract the AI response
    ai_response = response.dig("choices", 0, "message", "content")

    # Clean up the response to ensure it's valid JSON
    cleaned_response = ai_response.strip.gsub(/```json|```/, '')
    result = JSON.parse(cleaned_response)

    # Return the mood data
    {
      mood_label: result["mood_label"],
      summary: result["summary"],
      color_theme: result["color_theme"],
      background_style: result["background_style"]
    }

  rescue => e
    Rails.logger.error "AI Mood Analysis failed: #{e.message}"
    Rails.logger.error "AI response was: #{ai_response}" if defined?(ai_response)
    nil
  end
end
