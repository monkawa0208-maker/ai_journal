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
    <<~PROMPT
    あなたは共感的で肯定的な英語の先生です。以下は英語学習中ユーザーの日記です。

    【今日の日記】
    タイトル: #{@entry.title}
    本文:
    #{@entry.content}

    #下記フォーマットで日本語で回答して下さい。ユーザーの気持ちや状況を汲み取り、短い励ましや洞察、次の一歩の提案を日本語で返してください。断定しすぎず、優しく、読みやすく。
            # 英文アドバイス（英語の誤りがなければ褒めてください。英語の誤りがあれば日本語で教えて下さい（修正点があればどこが修正点か、なぜ修正が必要か。修正点ごとに箇条書きで回答してください。））
            # 修正後の文章（英語の誤りがなければ「このままでOKです！」と返してください。英語の誤りがあれば修正後の文章を送ります。）
            # より良い表現（よりネイティブが使う表現に書き換えることができれば送ります。）
            # コメント (英文についてではなく日記の内容についてコメントして下さい。必ずポジティブな表現を使って下さい)
    PROMPT
  end

  def complete_with_openai(prompt)
    require 'http'
    api_key = ENV.fetch('OPENAI_API_KEY')
    base_url = 'https://api.openai.com/v1/chat/completions'

    payload = {
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a helpful assistant that writes concise, empathetic Japanese feedback.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 600
    }

    response = HTTP.headers(
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json'
    ).post(base_url, json: payload)

    unless response.status.success?
      raise "OpenAI API error: #{response.status} #{response.body.to_s}"
    end

    body = JSON.parse(response.body.to_s)
    body.dig('choices', 0, 'message', 'content') || ''
  end
end


