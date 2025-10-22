class AiFeedbackGenerator
  def self.call(entry)
    new(entry).call
  end

  def initialize(entry)
    @entry = entry
    @user = entry.user
  end

  def call
    complete_with_openai(build_prompt)
  end

  private

  def build_prompt
    AiFeedbackPromptTemplate.build(
      content: @entry.content
    )
  end

  def complete_with_openai(prompt)
    require 'http'
    
    payload = {
      model: AiServiceConfig.default_model,
      messages: [
        { role: 'system', content: AiServiceConfig.feedback_config[:system_message] },
        { role: 'user', content: prompt }
      ],
      temperature: AiServiceConfig.feedback_config[:temperature],
      max_tokens: AiServiceConfig.feedback_config[:max_tokens]
    }

    response = HTTP.headers(AiServiceConfig.headers).post(AiServiceConfig.base_url, json: payload)

    unless response.status.success?
      raise "OpenAI API error: #{response.status} #{response.body.to_s}"
    end

    body = JSON.parse(response.body.to_s)
    body.dig('choices', 0, 'message', 'content') || ''
  end
end


