require 'rails_helper'

RSpec.describe AiFeedbackPromptTemplate, type: :service do
  describe '.build' do
    let(:title) { 'My First Day' }
    let(:content) { 'Today was a great day!' }

    it 'タイトルと内容を含むプロンプトを生成すること' do
      prompt = AiFeedbackPromptTemplate.build(title: title, content: content)
      
      expect(prompt).to be_a(String)
      expect(prompt).to include(title)
      expect(prompt).to include(content)
    end

    it '日本語の指示が含まれていること' do
      prompt = AiFeedbackPromptTemplate.build(title: title, content: content)
      
      expect(prompt).to include('あなたは共感的で肯定的な英語の先生です')
      expect(prompt).to include('【今日の日記】')
      expect(prompt).to include('英文アドバイス')
      expect(prompt).to include('修正後の文章')
      expect(prompt).to include('より良い表現')
      expect(prompt).to include('コメント')
    end

    it 'フォーマット指示が含まれていること' do
      prompt = AiFeedbackPromptTemplate.build(title: title, content: content)
      
      expect(prompt).to include('フォーマットで日本語で回答')
      expect(prompt).to include('箇条書き')
    end
  end

  describe 'TEMPLATE定数' do
    it 'プレースホルダーが含まれていること' do
      expect(AiFeedbackPromptTemplate::TEMPLATE).to include('%{title}')
      expect(AiFeedbackPromptTemplate::TEMPLATE).to include('%{content}')
    end
  end
end

