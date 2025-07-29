# app/services/banner_image_service.rb
class BannerImageService
  def self.generate_for_entry(entry)
    return nil unless entry.ai_mood_label.present?

    begin
      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
      prompt = self.build_prompt(entry)

      images_client = client.images
      response = images_client.generate(
        parameters: {
          prompt: prompt,
          model: "dall-e-3",
          size: "1792x1024",
          quality: "standard",
          n: 1
        }
      )

      image_url = response.dig("data", 0, "url")
      return nil unless image_url

      self.upload_to_cloudinary(image_url, entry)
    rescue => e
      Rails.logger.error "Banner generation failed: #{e.message}"
      nil
    end
  end

  private

  def self.build_prompt(entry)
    mood = entry.ai_mood_label
    content_snippet = entry.content&.truncate(150) || ""

    "Create a realistic banner image representing the emotion '#{mood}' inspired by this journal entry: '#{content_snippet}'.
    Style: soft gradients, gentle shapes, calming colors that reflect both the mood and themes from the entry.
    ABSOLUTELY NO TEXT, NO WORDS, NO LETTERS, NO SYMBOLS - pure visual representation only.
    No people, no specific objects.
    Evoke the feeling of #{mood} and the essence of the entry's themes through color, form, and atmosphere only.
    Mobile-friendly banner format."
  end

  def self.upload_to_cloudinary(image_url, entry)
    result = Cloudinary::Uploader.upload(
      image_url,
      folder: "journal_banners",
      public_id: "entry_#{entry.id}_banner",
      resource_type: "image"
    )

    result['secure_url']
  rescue => e
    Rails.logger.error "Cloudinary upload failed: #{e.message}"
    nil
  end
end
