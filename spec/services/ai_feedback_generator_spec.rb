require 'rails_helper'

RSpec.describe AiFeedbackGenerator, type: :service do
  
  before do
    @user = FactoryBot.create(:user)
    @entry = FactoryBot.create(:entry, user: @user, title: 'My First Day', content: 'Today was a great day!')
    
    # 環境変数のモック
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_return('test_api_key')
  end

  describe '.call' do
    it 'クラスメソッドでインスタンスを生成してcallを実行すること' do
      generator = instance_double(AiFeedbackGenerator)
      allow(AiFeedbackGenerator).to receive(:new).with(@entry).and_return(generator)
      allow(generator).to receive(:call).and_return('フィードバック')
      
      result = AiFeedbackGenerator.call(@entry)
      
      expect(result).to eq('フィードバック')
      expect(AiFeedbackGenerator).to have_received(:new).with(@entry)
      expect(generator).to have_received(:call)
    end
  end

  describe '#initialize' do
    it 'エントリーとユーザーを設定すること' do
      generator = AiFeedbackGenerator.new(@entry)
      
      expect(generator.instance_variable_get(:@entry)).to eq(@entry)
      expect(generator.instance_variable_get(:@user)).to eq(@user)
    end
  end

  describe '#call' do
    it 'OpenAI APIが成功レスポンスを返した場合、フィードバックを返すこと' do
      # HTTPレスポンスのモック
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => '素晴らしい日記ですね！'
            }
          }
        ]
      }.to_json
      
      response_double = double('response', 
        status: double('status', success?: true),
        body: response_body
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      
      generator = AiFeedbackGenerator.new(@entry)
      result = generator.call
      
      expect(result).to eq('素晴らしい日記ですね！')
    end

    it 'OpenAI APIがエラーレスポンスを返した場合、エラーを発生させること' do
      response_double = double('response',
        status: double('status', success?: false),
        body: 'Error message'
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      
      generator = AiFeedbackGenerator.new(@entry)
      
      expect { generator.call }.to raise_error(RuntimeError, /OpenAI API error/)
    end

    it 'レスポンスにcontentが含まれていない場合、空文字列を返すこと' do
      response_body = {
        'choices' => [
          {
            'message' => {}
          }
        ]
      }.to_json
      
      response_double = double('response',
        status: double('status', success?: true),
        body: response_body
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      
      generator = AiFeedbackGenerator.new(@entry)
      result = generator.call
      
      expect(result).to eq('')
    end
  end

  describe '#build_prompt (private)' do
    it 'エントリーのタイトルと内容を含むプロンプトを生成すること' do
      generator = AiFeedbackGenerator.new(@entry)
      prompt = generator.send(:build_prompt)
      
      expect(prompt).to include(@entry.title)
      expect(prompt).to include(@entry.content)
      expect(prompt).to include('あなたは共感的で肯定的な英語の先生です')
    end
  end

  describe 'API呼び出し' do
    it '正しいヘッダーとペイロードでAPIを呼び出すこと' do
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => 'テストフィードバック'
            }
          }
        ]
      }.to_json
      
      response_double = double('response',
        status: double('status', success?: true),
        body: response_body
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).with(
        'Authorization' => 'Bearer test_api_key',
        'Content-Type' => 'application/json'
      ).and_return(http_double)
      
      expect(http_double).to receive(:post).with(
        'https://api.openai.com/v1/chat/completions',
        json: hash_including(
          model: 'gpt-4o-mini',
          temperature: 0.7,
          max_tokens: 600
        )
      ).and_return(response_double)
      
      generator = AiFeedbackGenerator.new(@entry)
      generator.call
    end
  end
end

