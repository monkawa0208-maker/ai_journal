require 'rails_helper'

RSpec.describe AiTitleGenerator, type: :service do
  
  before do
    # 環境変数のモック
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_return('test_api_key')
  end

  describe '.call' do
    it 'クラスメソッドでインスタンスを生成してcallを実行すること' do
      generator = instance_double(AiTitleGenerator)
      allow(AiTitleGenerator).to receive(:new).with('Test content').and_return(generator)
      allow(generator).to receive(:call).and_return('Generated Title')
      
      result = AiTitleGenerator.call('Test content')
      
      expect(result).to eq('Generated Title')
      expect(AiTitleGenerator).to have_received(:new).with('Test content')
      expect(generator).to have_received(:call)
    end
  end

  describe '#initialize' do
    it 'コンテンツを設定すること' do
      generator = AiTitleGenerator.new('Test content')
      
      expect(generator.instance_variable_get(:@content)).to eq('Test content')
    end
  end

  describe '#call' do
    context 'OpenAI APIが成功レスポンスを返した場合' do
      it 'タイトルを返すこと' do
        response_body = {
          'choices' => [
            {
              'message' => {
                'content' => 'My First Day at School'
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
        
        generator = AiTitleGenerator.new('Today was my first day at school.')
        result = generator.call
        
        expect(result).to eq('My First Day at School')
      end

      it '30文字を超える場合は切り詰めること' do
        long_title = 'This is a very long title that exceeds thirty characters limit'
        response_body = {
          'choices' => [
            {
              'message' => {
                'content' => long_title
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
        
        generator = AiTitleGenerator.new('Test content')
        result = generator.call
        
        expect(result.length).to be <= 30
        expect(result).to end_with('...')
      end

      it '改行や余分な空白を削除すること' do
        response_body = {
          'choices' => [
            {
              'message' => {
                'content' => "My    Title\n   With\nSpaces"
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
        
        generator = AiTitleGenerator.new('Test content')
        result = generator.call
        
        expect(result).to eq('My Title With Spaces')
        expect(result).not_to include("\n")
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
        
        generator = AiTitleGenerator.new('Test content')
        result = generator.call
        
        expect(result).to eq('')
      end
    end

    context 'OpenAI APIがエラーレスポンスを返した場合' do
      it 'エラーを発生させること' do
        response_double = double('response',
          status: double('status', success?: false),
          body: 'Error message'
        )
        
        http_double = double('http')
        allow(HTTP).to receive(:headers).and_return(http_double)
        allow(http_double).to receive(:post).and_return(response_double)
        
        generator = AiTitleGenerator.new('Test content')
        
        expect { generator.call }.to raise_error(RuntimeError, /OpenAI API error/)
      end
    end
  end

  describe '#build_prompt (private)' do
    it 'コンテンツを含むプロンプトを生成すること' do
      generator = AiTitleGenerator.new('Today was a great day!')
      prompt = generator.send(:build_prompt)
      
      expect(prompt).to include('Today was a great day!')
      expect(prompt).to include('日記のタイトル生成アシスタント')
      expect(prompt).to include('簡潔で適切なタイトルを生成してください')
    end
  end

  describe 'API呼び出し' do
    it '正しいヘッダーとペイロードでAPIを呼び出すこと' do
      response_body = {
        'choices' => [
          {
            'message' => {
              'content' => 'Test Title'
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
          max_tokens: 100
        )
      ).and_return(response_double)
      
      generator = AiTitleGenerator.new('Test content')
      generator.call
    end
  end
end

