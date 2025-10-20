class AiTranslator
  class TranslationError < StandardError; end

  def self.call(japanese_text)
    new(japanese_text).call
  end

  def initialize(japanese_text)
    @japanese_text = japanese_text
  end

  def call
    return "" if @japanese_text.blank?

    require 'http'

    payload = {
      model: AiServiceConfig.default_model,
      messages: [
        {
          role: "system",
          content: AiServiceConfig.translation_config[:system_message]
        },
        {
          role: "user",
          content: build_prompt
        }
      ],
      temperature: AiServiceConfig.translation_config[:temperature],
      max_tokens: AiServiceConfig.translation_config[:max_tokens]
    }

    response = HTTP.headers(AiServiceConfig.headers).post(AiServiceConfig.base_url, json: payload)

    unless response.status.success?
      error_message = "OpenAI API error: #{response.status} #{response.body.to_s}"
      Rails.logger.error("[AiTranslator] #{error_message}")
      raise TranslationError, "翻訳処理中にエラーが発生しました: #{response.status}"
    end

    body = JSON.parse(response.body.to_s)
    translation = body.dig("choices", 0, "message", "content")
    
    raise TranslationError, "翻訳結果が取得できませんでした" if translation.blank?

    translation.strip
  rescue TranslationError => e
    raise e
  rescue StandardError => e
    Rails.logger.error("[AiTranslator] #{e.class}: #{e.message}")
    raise TranslationError, "翻訳処理中にエラーが発生しました: #{e.message}"
  end

  private

  def build_prompt
    "#{AiTranslatorPromptTemplate.build}\n#{@japanese_text}"
  end
end

