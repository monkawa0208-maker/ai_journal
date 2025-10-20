# AI Service Configuration
class AiServiceConfig
  class << self
    def openai_api_key
      ENV.fetch('OPENAI_API_KEY')
    end

    def base_url
      'https://api.openai.com/v1/chat/completions'
    end

    def default_model
      'gpt-4o-mini'
    end

    def feedback_config
      {
        temperature: 0.7,
        max_tokens: 600,
        system_message: 'You are a helpful assistant that writes concise, empathetic Japanese feedback.'
      }
    end

    def translation_config
      {
        temperature: 0.7,
        max_tokens: 2000,
        system_message: 'You are a professional translator specialized in translating Japanese to natural, fluent English.'
      }
    end

    def headers
      {
        'Authorization' => "Bearer #{openai_api_key}",
        'Content-Type' => 'application/json'
      }
    end
  end
end
