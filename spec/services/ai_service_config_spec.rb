require 'rails_helper'

RSpec.describe AiServiceConfig, type: :service do
  before do
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_return('test_api_key')
  end

  describe '.openai_api_key' do
    it 'OpenAI APIキーを返すこと' do
      expect(AiServiceConfig.openai_api_key).to eq('test_api_key')
    end
  end

  describe '.base_url' do
    it 'OpenAI API URLを返すこと' do
      expect(AiServiceConfig.base_url).to eq('https://api.openai.com/v1/chat/completions')
    end
  end

  describe '.default_model' do
    it 'デフォルトモデル名を返すこと' do
      expect(AiServiceConfig.default_model).to eq('gpt-4o-mini')
    end
  end

  describe '.feedback_config' do
    it 'フィードバック設定を返すこと' do
      config = AiServiceConfig.feedback_config
      
      expect(config).to be_a(Hash)
      expect(config[:temperature]).to eq(0.7)
      expect(config[:max_tokens]).to eq(600)
      expect(config[:system_message]).to be_a(String)
      expect(config[:system_message]).to include('helpful assistant')
    end
  end

  describe '.translation_config' do
    it '翻訳設定を返すこと' do
      config = AiServiceConfig.translation_config
      
      expect(config).to be_a(Hash)
      expect(config[:temperature]).to eq(0.7)
      expect(config[:max_tokens]).to eq(2000)
      expect(config[:system_message]).to be_a(String)
      expect(config[:system_message]).to include('professional translator')
    end
  end

  describe '.headers' do
    it 'APIリクエストヘッダーを返すこと' do
      headers = AiServiceConfig.headers
      
      expect(headers).to be_a(Hash)
      expect(headers['Authorization']).to eq('Bearer test_api_key')
      expect(headers['Content-Type']).to eq('application/json')
    end
  end
end

