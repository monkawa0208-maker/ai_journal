require 'rails_helper'

RSpec.describe AiTranslator, type: :service do
  
  before do
    # 環境変数のモック
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_return('test_api_key')
  end

  describe '.call' do
    it 'クラスメソッドでインスタンスを生成してcallを実行すること' do
      translator = instance_double(AiTranslator)
      allow(AiTranslator).to receive(:new).with('こんにちは').and_return(translator)
      allow(translator).to receive(:call).and_return('Hello')
      
      result = AiTranslator.call('こんにちは')
      
      expect(result).to eq('Hello')
      expect(AiTranslator).to have_received(:new).with('こんにちは')
      expect(translator).to have_received(:call)
    end
  end

  describe '#initialize' do
    it '日本語テキストを設定すること' do
      translator = AiTranslator.new('こんにちは')
      
      expect(translator.instance_variable_get(:@japanese_text)).to eq('こんにちは')
    end
  end

  describe '#call' do
    it '空文字列を渡した場合、空文字列を返すこと' do
      translator = AiTranslator.new('')
      result = translator.call
      
      expect(result).to eq('')
    end

    it 'nilを渡した場合、空文字列を返すこと' do
      translator = AiTranslator.new(nil)
      result = translator.call
      
      expect(result).to eq('')
    end

    it 'OpenAI APIが成功レスポンスを返した場合、翻訳結果を返すこと' do
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => "# 翻訳後の文章\nHello, this is a test.\n\n# Key Points\n- テスト: test"
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
      
      translator = AiTranslator.new('こんにちは、これはテストです。')
      result = translator.call
      
      expect(result).to include('翻訳後の文章')
      expect(result).to include('Hello, this is a test.')
    end

    it 'OpenAI APIがエラーレスポンスを返した場合、TranslationErrorを発生させること' do
      response_double = double('response',
        status: double('status', success?: false, to_s: '500'),
        body: 'Internal Server Error'
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      
      translator = AiTranslator.new('こんにちは')
      
      expect { translator.call }.to raise_error(AiTranslator::TranslationError, /翻訳処理中にエラーが発生しました/)
    end

    it '翻訳結果が空の場合、TranslationErrorを発生させること' do
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => ''
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
      
      translator = AiTranslator.new('こんにちは')
      
      expect { translator.call }.to raise_error(AiTranslator::TranslationError, '翻訳結果が取得できませんでした')
    end

    it 'JSON.parseでエラーが発生した場合、TranslationErrorを発生させること' do
      response_double = double('response',
        status: double('status', success?: true),
        body: 'invalid json'
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      
      translator = AiTranslator.new('こんにちは')
      
      expect { translator.call }.to raise_error(AiTranslator::TranslationError, /翻訳処理中にエラーが発生しました/)
    end

    it 'APIエラー時にRails.loggerにエラーをログ出力すること' do
      response_double = double('response',
        status: double('status', success?: false, to_s: '500'),
        body: 'Error'
      )
      
      http_double = double('http')
      allow(HTTP).to receive(:headers).and_return(http_double)
      allow(http_double).to receive(:post).and_return(response_double)
      allow(Rails.logger).to receive(:error)
      
      translator = AiTranslator.new('こんにちは')
      
      begin
        translator.call
      rescue AiTranslator::TranslationError
        # エラーは期待通り
      end
      
      expect(Rails.logger).to have_received(:error).with(/\[AiTranslator\]/)
    end
  end

  describe '#build_prompt (private)' do
    it '翻訳用のプロンプトを生成すること' do
      translator = AiTranslator.new('こんにちは')
      prompt = translator.send(:build_prompt)
      
      expect(prompt).to include('こんにちは')
    end
  end

  describe 'API呼び出し' do
    it '正しいヘッダーとペイロードでAPIを呼び出すこと' do
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => 'Translation result'
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
      
      expect(http_double).to receive(:post).with(
        'https://api.openai.com/v1/chat/completions',
        json: hash_including(
          model: 'gpt-4o-mini',
          temperature: 0.7,
          max_tokens: 2000
        )
      ).and_return(response_double)
      
      translator = AiTranslator.new('こんにちは')
      translator.call
    end
  end
end

