class AiTranslator
  class TranslationError < StandardError; end

  def self.call(japanese_text)
    new(japanese_text).call
  end

  def initialize(japanese_text)
    @japanese_text = japanese_text
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def call
    return "" if @japanese_text.blank?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: @japanese_text
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      }
    )

    translation = response.dig("choices", 0, "message", "content")
    raise TranslationError, "翻訳結果が取得できませんでした" if translation.blank?

    translation.strip
  rescue StandardError => e
    Rails.logger.error("[AiTranslator] #{e.class}: #{e.message}")
    raise TranslationError, "翻訳処理中にエラーが発生しました: #{e.message}"
  end

  private

  def system_prompt
    <<~PROMPT
      You are a professional translator specialized in translating Japanese to natural, fluent English.
      
      Guidelines:
      - Translate the Japanese text into natural, conversational English
      - Maintain the tone and style of the original text
      - Use appropriate vocabulary and grammar for diary/journal entries
      - Keep the translation clear and easy to read
      - Please explain in Japanese the key points of this translation and the meanings of difficult words.      

      Translate the following Japanese text to English:
    PROMPT
  end
end

