# app/services/mood_analysis_service.rb
class MoodAnalysisService
  # Predefined emotion categories for consistent filtering/searching
  EMOTION_CATEGORIES = [
    # Positive Emotions
    'joyful', 'grateful', 'excited', 'peaceful', 'content', 'optimistic',
    'inspired', 'proud', 'confident', 'hopeful', 'energetic', 'loved',

    # Neutral/Reflective Emotions
    'contemplative', 'nostalgic', 'curious', 'calm', 'focused', 'determined',

    # Challenging Emotions
    'anxious', 'frustrated', 'overwhelmed', 'sad', 'angry', 'stressed',
    'worried', 'lonely', 'disappointed', 'confused', 'tired', 'restless'
  ].freeze

  def initialize(journal_entry)
    @journal_entry = journal_entry
    @client = OpenAI::Client.new
  end

  def analyze
    return nil unless @journal_entry.content.present? || @journal_entry.has_media?

  # Use the content_for_ai_analysis method to handle different input types
  content_to_analyze = @journal_entry.content_for_ai_analysis

  response = @client.chat(
    parameters: {
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: build_emotion_prompt
        },
        {
          role: "user",
          content: content_to_analyze
        }
      ]
    }
  )

  # Extract the AI response
  ai_response = response.dig("choices", 0, "message", "content")

  # Clean up the response to ensure it's valid JSON
  cleaned_response = ai_response.strip.gsub(/```json|```/, '')
  result = JSON.parse(cleaned_response)

  # Validate that the emotion is from our predefined list
  selected_emotion = validate_emotion(result["mood_label"])

  # Return the mood data with both nutshell and summary
  {
    mood_label: selected_emotion,
    nutshell: result["nutshell"] || 'Brief summary unavailable.',
    summary: result["summary"] || 'Detailed summary unavailable.',
    color_theme: get_emotion_color(selected_emotion),
    background_style: get_emotion_background(selected_emotion)
  }

  rescue => e
    Rails.logger.error "AI Mood Analysis failed: #{e.message}"
    Rails.logger.error "AI response was: #{ai_response}" if defined?(ai_response)
    # Return default response with both fields
    {
      mood_label: 'contemplative',
      nutshell: 'Entry saved successfully.',
      summary: 'Your journal entry has been saved and is ready for you to review.',
      color_theme: get_emotion_color('contemplative'),
      background_style: get_emotion_background('contemplative')
    }
  end

  # Class method to get all available emotions for filtering
  def self.emotion_categories
    EMOTION_CATEGORIES
  end

  # Class method to get emotions grouped by type
  def self.emotions_by_category
    {
      'Positive' => ['joyful', 'grateful', 'excited', 'peaceful', 'content', 'optimistic',
                      'inspired', 'proud', 'confident', 'hopeful', 'energetic', 'loved'],
      'Reflective' => ['contemplative', 'nostalgic', 'curious', 'calm', 'focused', 'determined'],
      'Challenging' => ['anxious', 'frustrated', 'overwhelmed', 'sad', 'angry', 'stressed',
                        'worried', 'lonely', 'disappointed', 'confused', 'tired', 'restless']
    }
  end

  private

  def build_emotion_prompt
    emotion_list = EMOTION_CATEGORIES.join(', ')

    <<~PROMPT
      You are a supportive and insightful mood analyst. Analyze this journal entry with warmth and understanding, focusing on growth, resilience, and positive aspects wherever possible.

      Look for the overall emotional journey - what the person experienced, learned, or felt. When analyzing challenging emotions, frame them as part of the human experience and growth process.

      You MUST select the mood_label from this exact list only:
      #{emotion_list}

      Choose the single emotion that best captures the overall emotional tone of the entry.

      Also provide:
      - A brief "nutshell" summary (1-2 sentences) that captures the key mood and main points quickly
      - A detailed "summary" (3-4 sentences) that provides a thoughtful, encouraging analysis of the person's experience, highlighting positive elements, lessons learned, or inner strength shown
      - Focus on hope, growth, and the value of their emotional journey
      - The response must be valid JSON only

      Respond ONLY in this exact JSON format:
      {
        "mood_label": "one_emotion_from_the_list_above",
        "nutshell": "brief 1-2 sentence overview of mood and main points",
        "summary": "detailed 3-4 sentence encouraging analysis"
      }

      Important: The mood_label must be exactly one of the predefined emotions listed above, with no variations or alternatives.
    PROMPT
  end

  def validate_emotion(ai_emotion)
    # Ensure the AI selected emotion is in our predefined list
    normalized_emotion = ai_emotion&.downcase&.strip

    if EMOTION_CATEGORIES.include?(normalized_emotion)
      normalized_emotion
    else
      # Fallback to closest match or default
      find_closest_emotion(normalized_emotion) || 'contemplative'
    end
  end

  def find_closest_emotion(ai_emotion)
    return nil unless ai_emotion.present?

    # Simple fuzzy matching for common variations
    case ai_emotion.downcase
    when /happy|joy|cheerful|delighted/
      'joyful'
    when /thank|appreciate/
      'grateful'
    when /enthus|thrill|pumped/
      'excited'
    when /relax|serene|tranquil/
      'peaceful'
    when /satisfy|pleased/
      'content'
    when /positive|upbeat/
      'optimistic'
    when /creative|motivated/
      'inspired'
    when /accomplish|achieve/
      'proud'
    when /sure|certain/
      'confident'
    when /expect|anticipat/
      'hopeful'
    when /active|vigor/
      'energetic'
    when /affection|care/
      'loved'
    when /think|reflect|ponder/
      'contemplative'
    when /memory|remember|past/
      'nostalgic'
    when /wonder|interest/
      'curious'
    when /quiet|still/
      'calm'
    when /concentrate|attentive/
      'focused'
    when /resolve|commit/
      'determined'
    when /nervous|worry|fear/
      'anxious'
    when /annoy|irritat|upset/
      'frustrated'
    when /too much|busy|burden/
      'overwhelmed'
    when /sorrow|grief|down/
      'sad'
    when /mad|rage|furious/
      'angry'
    when /pressure|tension/
      'stressed'
    when /concern|trouble/
      'worried'
    when /alone|isolat/
      'lonely'
    when /let down|failed/
      'disappointed'
    when /puzzl|unclear/
      'confused'
    when /exhaust|weary/
      'tired'
    when /agitat|unsettl/
      'restless'
    else
      nil
    end
  end

  def get_emotion_color(emotion)
    case emotion
    # Positive emotions - various greens and warm colors
    when 'joyful', 'excited', 'energetic'
      '#28a745' # Bright green
    when 'grateful', 'loved', 'content'
      '#20c997' # Teal green
    when 'peaceful', 'calm'
      '#17a2b8' # Calm blue
    when 'optimistic', 'hopeful', 'confident'
      '#ffc107' # Warm yellow
    when 'inspired', 'proud'
      '#6f42c1' # Purple

    # Neutral/Reflective emotions - blues and grays
    when 'contemplative', 'focused', 'curious'
      '#6c757d' # Neutral gray
    when 'nostalgic', 'determined'
      '#495057' # Darker gray

    # Challenging emotions - reds and oranges
    when 'anxious', 'worried', 'stressed'
      '#fd7e14' # Orange
    when 'frustrated', 'angry'
      '#dc3545' # Red
    when 'overwhelmed', 'confused', 'restless'
      '#e83e8c' # Pink-red
    when 'sad', 'lonely', 'disappointed'
      '#6610f2' # Purple-blue
    when 'tired'
      '#868e96' # Muted gray

    else
      '#6c757d' # Default gray
    end
  end

  def get_emotion_background(emotion)
    case emotion
    when 'joyful', 'excited', 'energetic'
      'linear-gradient(135deg, #fff9c4 0%, #f5f5dc 100%)'
    when 'grateful', 'loved', 'content'
      'linear-gradient(135deg, #e8f5e8 0%, #f0fff0 100%)'
    when 'peaceful', 'calm'
      'linear-gradient(135deg, #e6f3ff 0%, #f0f8ff 100%)'
    when 'optimistic', 'hopeful', 'confident'
      'linear-gradient(135deg, #fff8dc 0%, #fffacd 100%)'
    when 'inspired', 'proud'
      'linear-gradient(135deg, #f3e5f5 0%, #faf0e6 100%)'
    when 'contemplative', 'focused', 'curious'
      'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)'
    when 'nostalgic', 'determined'
      'linear-gradient(135deg, #f1f3f4 0%, #e8eaed 100%)'
    when 'anxious', 'worried', 'stressed'
      'linear-gradient(135deg, #fff3cd 0%, #fef9e7 100%)'
    when 'frustrated', 'angry'
      'linear-gradient(135deg, #f8d7da 0%, #fdf2f2 100%)'
    when 'overwhelmed', 'confused', 'restless'
      'linear-gradient(135deg, #fce4ec 0%, #f3e5f5 100%)'
    when 'sad', 'lonely', 'disappointed'
      'linear-gradient(135deg, #e1e5f2 0%, #f0f4f8 100%)'
    when 'tired'
      'linear-gradient(135deg, #f5f5f5 0%, #eeeeee 100%)'
    else
      'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)'
    end
  end
end
