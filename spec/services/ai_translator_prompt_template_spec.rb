require 'rails_helper'

RSpec.describe AiTranslatorPromptTemplate, type: :service do
  describe '.build' do
    it 'プロンプトテンプレートを返すこと' do
      prompt = AiTranslatorPromptTemplate.build
      
      expect(prompt).to be_a(String)
      expect(prompt).not_to be_empty
    end

    it '翻訳用の指示が含まれていること' do
      prompt = AiTranslatorPromptTemplate.build
      
      expect(prompt).to include('professional translator')
      expect(prompt).to include('Japanese to natural, fluent English')
    end

    it 'フォーマット指示が含まれていること' do
      prompt = AiTranslatorPromptTemplate.build
      
      expect(prompt).to include('# 翻訳後の文章')
      expect(prompt).to include('# Key Points')
      expect(prompt).to include('# Vocabulary')
    end

    it 'ガイドラインが含まれていること' do
      prompt = AiTranslatorPromptTemplate.build
      
      expect(prompt).to include('Guidelines:')
      expect(prompt).to include('natural, conversational English')
      expect(prompt).to include('diary/journal entries')
    end

    it '日本語での説明指示が含まれていること' do
      prompt = AiTranslatorPromptTemplate.build
      
      expect(prompt).to include('必ず下記のフォーマットで回答')
      expect(prompt).to include('日本語で説明')
    end
  end

  describe 'TEMPLATE定数' do
    it 'テンプレートが定義されていること' do
      expect(AiTranslatorPromptTemplate::TEMPLATE).to be_a(String)
      expect(AiTranslatorPromptTemplate::TEMPLATE).not_to be_empty
    end
  end
end

