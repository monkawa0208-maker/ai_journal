class AiTitleGenerator
  def self.call(content)
    new(content).call
  end

  def initialize(content)
    @content = content
  end

  def call
    generate_title_with_openai
  end

  private

  def build_prompt
    <<~PROMPT
      あなたは日記のタイトル生成アシスタントです。以下の日記の内容から、簡潔で適切なタイトルを生成してください。

      【日記の内容】
      #{@content}

      上記の日記内容から、30文字以内の簡潔で内容を表す英語のタイトルを生成してください。
      タイトルのみを返答し、余計な説明は不要です。
    PROMPT
  end

  def generate_title_with_openai
    require 'http'
    
    payload = {
      model: AiServiceConfig.default_model,
      messages: [
        { role: 'system', content: 'あなたは日記のタイトル生成アシスタントです。簡潔で適切なタイトルを生成してください。' },
        { role: 'user', content: build_prompt }
      ],
      temperature: 0.7,
      max_tokens: 50
    }

    response = HTTP.headers(AiServiceConfig.headers).post(AiServiceConfig.base_url, json: payload)

    unless response.status.success?
      raise "OpenAI API error: #{response.status} #{response.body.to_s}"
    end

    body = JSON.parse(response.body.to_s)
    title = body.dig('choices', 0, 'message', 'content') || ''
    
    # タイトルをクリーンアップ（改行や余分な空白を削除、30文字制限）
    title.strip.gsub(/\s+/, ' ').truncate(30, omission: '...')
  end
end

