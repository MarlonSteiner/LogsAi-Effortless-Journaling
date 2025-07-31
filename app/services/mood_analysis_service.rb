# app/services/mood_analysis_service.rb
class MoodAnalysisService
  EMOTION_CATEGORIES = [
    'joyful', 'anxious', 'contemplative', 'excited', 'peaceful', 'frustrated',
    'grateful', 'melancholy', 'hopeful', 'overwhelmed', 'content', 'restless',
    'inspired', 'lonely', 'confident', 'worried', 'nostalgic', 'energetic',
    'confused', 'satisfied', 'curious', 'disappointed', 'optimistic', 'stressed'
  ].freeze

  def self.analyze(content_or_file, input_type)
    new(content_or_file, input_type).analyze
  end

  def initialize(content_or_file, input_type)
    @content_or_file = content_or_file
    @input_type = input_type
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
  end

  def analyze
    prompt = build_prompt

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 500,
        temperature: 0.7
      }
    )

    parse_response(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    fallback_response
  end

  private

  def build_prompt
    base_context = <<~CONTEXT
      You are an AI assistant that analyzes journal entries to help users understand their emotional patterns.
      Your tone should be warm, supportive, and encouraging - like a caring friend who helps people reflect on their experiences.

      Available emotion categories: #{EMOTION_CATEGORIES.join(', ')}

      Please analyze the following #{@input_type} journal entry and respond with a JSON object containing:
      - title: A warm, engaging title (3-6 words) that captures the essence
      - mood: The primary emotion from the available categories
      - color_theme: A color that represents the mood (hex code)
      - background_style: A brief description of visual style that matches the mood
      - summary: A supportive 3-4 sentence summary highlighting positive aspects and growth
      - nutshell: A brief 1-2 sentence uplifting takeaway

      Make the analysis encouraging and focus on positive aspects, personal growth, and resilience.
    CONTEXT

    case @input_type
    when 'text', 'audio'
      # For text and audio (transcribed), analyze the content directly
      "#{base_context}\n\nContent to analyze:\n#{@content_or_file}"
    when 'image', 'video'
      # For media files, we'll need to handle them differently
      # This is a simplified version - in production, you'd want to use GPT-4 Vision API
      "#{base_context}\n\nThis is a #{@input_type} file. Please provide a general positive analysis for a #{@input_type} journal entry, focusing on the act of visual journaling and self-expression."
    end
  end

  # REPLACE your parse_response method in MoodAnalysisService with this:
  def parse_response(response_text)
    # Clean up the response text - remove code block markers
    cleaned_response = response_text.strip

    # Remove ```json and ``` if present
    if cleaned_response.start_with?('```json')
      cleaned_response = cleaned_response.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif cleaned_response.start_with?('```')
      cleaned_response = cleaned_response.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    # Try to parse as JSON
    parsed = JSON.parse(cleaned_response)

    {
      title: sanitize_title(parsed['title']),
      mood: validate_mood(parsed['mood']),
      color_theme: sanitize_color(parsed['color_theme']),
      background_style: sanitize_text(parsed['background_style']),
      summary: sanitize_text(parsed['summary']),
      nutshell: sanitize_text(parsed['nutshell'])
    }
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    Rails.logger.error "Raw response: #{response_text}"
    Rails.logger.error "Cleaned response: #{cleaned_response}"

    # Try to extract from text as fallback
    extract_from_text(response_text)
  end

  def extract_from_text(text)
    # Fallback method to extract information from non-JSON response
    {
      title: extract_title_from_text(text),
      mood: extract_mood_from_text(text),
      color_theme: '#8B5CF6', # Default purple
      background_style: 'warm and welcoming',
      summary: extract_summary_from_text(text),
      nutshell: extract_nutshell_from_text(text)
    }
  end

  def extract_title_from_text(text)
    # Look for title patterns in the text
    title_match = text.match(/title[:\s]+([^\n\r]{3,50})/i)
    if title_match
      sanitize_title(title_match[1])
    else
      generate_default_title
    end
  end

  def extract_mood_from_text(text)
    # Look for mentioned emotions in the available categories
    found_moods = EMOTION_CATEGORIES.select { |mood| text.downcase.include?(mood) }
    found_moods.first || 'contemplative'
  end

  def extract_summary_from_text(text)
    # Extract summary section or use the whole text if short enough
    summary_match = text.match(/summary[:\s]+([^\n\r]{20,300})/i)
    if summary_match
      sanitize_text(summary_match[1])
    else
      text.length > 300 ? "#{text[0..297]}..." : text
    end
  end

  def extract_nutshell_from_text(text)
    # Look for nutshell section or create a brief version
    nutshell_match = text.match(/nutshell[:\s]+([^\n\r]{10,150})/i)
    if nutshell_match
      sanitize_text(nutshell_match[1])
    else
      sentences = text.split(/[.!?]/)
      first_sentence = sentences.first&.strip
      first_sentence.present? ? "#{first_sentence}." : "A meaningful moment of reflection."
    end
  end

  def sanitize_title(title)
    return generate_default_title unless title.present?

    title.strip.gsub(/[^\w\s\-']/, '').truncate(50)
  end

  def validate_mood(mood)
    return 'contemplative' unless mood.present?

    mood_cleaned = mood.downcase.strip
    EMOTION_CATEGORIES.include?(mood_cleaned) ? mood_cleaned : 'contemplative'
  end

  def sanitize_color(color)
    return '#8B5CF6' unless color.present?

    # Validate hex color format
    color.strip.match?(/^#[0-9A-Fa-f]{6}$/) ? color.strip : '#8B5CF6'
  end

  def sanitize_text(text)
    return '' unless text.present?

    text.strip.gsub(/[^\w\s\-'.,!?()]/, '').truncate(500)
  end

  def generate_default_title
    case @input_type
    when 'audio'
      'Voice Reflection'
    when 'image'
      'Visual Moment'
    when 'video'
      'Video Journal'
    when 'text'
      'Written Thoughts'
    else
      'Journal Entry'
    end
  end

  def fallback_response
    {
      title: generate_default_title,
      mood: 'contemplative',
      color_theme: '#8B5CF6',
      background_style: 'calm and peaceful',
      summary: case @input_type
              when 'audio'
                'You took time to express your thoughts through voice, creating a personal moment of reflection and self-expression.'
              when 'image'
                'You captured a meaningful visual moment, preserving a memory and expressing yourself creatively through imagery.'
              when 'video'
                'You created a video journal entry, combining visual and audio elements to document your experiences and thoughts.'
              else
                'You took time for self-reflection and personal expression, which is a valuable practice for mental wellness and growth.'
              end,
      nutshell: "A moment of mindful self-expression and reflection."
    }
  end
end
