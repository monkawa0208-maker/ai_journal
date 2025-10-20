require 'rails_helper'

RSpec.describe EntryService, type: :service do
  let(:user) { create(:user) }
  let(:entry) { create(:entry, user: user) }
  let(:valid_params) { { title: 'New Entry', content: 'New content', posted_on: Date.today } }
  let(:invalid_params) { { title: '', content: '', posted_on: nil } }

  describe '.create_entry' do
    context '有効なパラメータの場合' do
      it 'エントリーを作成できること' do
        result = EntryService.create_entry(user: user, entry_params: valid_params)
        
        expect(result[:success]).to be true
        expect(result[:entry]).to be_persisted
        expect(result[:entry].title).to eq('New Entry')
        expect(result[:message]).to eq('日記を投稿しました。')
      end

      it 'エントリー数が増えること' do
        expect {
          EntryService.create_entry(user: user, entry_params: valid_params)
        }.to change(Entry, :count).by(1)
      end
    end

    context '無効なパラメータの場合' do
      it 'エントリーが作成されないこと' do
        result = EntryService.create_entry(user: user, entry_params: invalid_params)
        
        expect(result[:success]).to be false
        expect(result[:entry]).not_to be_persisted
        expect(result[:errors]).to be_present
        expect(result[:message]).to eq('日記の投稿に失敗しました。')
      end

      it 'エントリー数が変わらないこと' do
        expect {
          EntryService.create_entry(user: user, entry_params: invalid_params)
        }.not_to change(Entry, :count)
      end
    end
  end

  describe '.update_entry' do
    context '有効なパラメータの場合' do
      it 'エントリーを更新できること' do
        result = EntryService.update_entry(entry: entry, entry_params: { title: 'Updated Title' })
        
        expect(result[:success]).to be true
        expect(result[:entry].title).to eq('Updated Title')
        expect(result[:message]).to eq('日記を更新しました。')
      end
    end

    context '無効なパラメータの場合' do
      it 'エントリーが更新されないこと' do
        original_title = entry.title
        result = EntryService.update_entry(entry: entry, entry_params: { title: '' })
        
        expect(result[:success]).to be false
        entry.reload
        expect(entry.title).to eq(original_title)
        expect(result[:message]).to eq('日記の更新に失敗しました。')
      end
    end

    context 'エントリーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = EntryService.new(user, valid_params, nil)
        result = service.update_entry
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('エントリーが見つかりません。')
      end
    end
  end

  describe '.destroy_entry' do
    let!(:entry_to_delete) { create(:entry, user: user) }

    it 'エントリーを削除できること' do
      result = EntryService.destroy_entry(entry: entry_to_delete)
      
      expect(result[:success]).to be true
      expect(result[:message]).to eq('日記を削除しました。')
      expect { entry_to_delete.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'エントリー数が減ること' do
      expect {
        EntryService.destroy_entry(entry: entry_to_delete)
      }.to change(Entry, :count).by(-1)
    end

    context 'エントリーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = EntryService.new(user, {}, nil)
        result = service.destroy_entry
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('エントリーが見つかりません。')
      end
    end
  end

  describe '.find_by_date' do
    let(:date) { Date.today }
    let!(:entry_on_date) { create(:entry, user: user, posted_on: date) }

    context '指定日のエントリーが存在する場合' do
      it 'エントリーを見つけられること' do
        result = EntryService.find_by_date(user: user, date: date)
        
        expect(result[:success]).to be true
        expect(result[:entry]).to eq(entry_on_date)
        expect(result[:message]).to eq('指定日の日記が見つかりました。')
      end
    end

    context '指定日のエントリーが存在しない場合' do
      it 'エラーメッセージを返すこと' do
        result = EntryService.find_by_date(user: user, date: date + 1.day)
        
        expect(result[:success]).to be false
        expect(result[:entry]).to be_nil
        expect(result[:message]).to eq('指定日の日記は見つかりませんでした。')
      end
    end
  end

  describe '.search_entries' do
    before do
      create(:entry, user: user, title: 'Ruby on Rails', content: 'Learning Rails', posted_on: Date.today)
      create(:entry, user: user, title: 'JavaScript', content: 'Learning JS', posted_on: Date.today - 1.day)
    end

    context '検索語が存在する場合' do
      it 'タイトルで検索できること' do
        result = EntryService.search_entries(user: user, search_term: 'Ruby')
        
        expect(result[:success]).to be true
        expect(result[:entries].count).to eq(1)
        expect(result[:entries].first.title).to include('Ruby')
        expect(result[:message]).to eq('1件の日記が見つかりました。')
      end

      it '本文で検索できること' do
        result = EntryService.search_entries(user: user, search_term: 'Rails')
        
        expect(result[:success]).to be true
        expect(result[:entries].count).to eq(1)
        expect(result[:entries].first.content).to include('Rails')
      end
    end

    context '検索語が空の場合' do
      it 'エラーメッセージを返すこと' do
        result = EntryService.search_entries(user: user, search_term: '')
        
        expect(result[:success]).to be false
        expect(result[:entries]).to eq([])
        expect(result[:message]).to eq('検索語が指定されていません。')
      end
    end
  end

  describe '#generate_ai_feedback' do
    let(:service) { EntryService.new(user, {}, entry) }

    context 'エントリーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = EntryService.new(user, {}, nil)
        result = service.generate_ai_feedback
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('エントリーが見つかりません。')
      end
    end

    context '既にフィードバックが存在する場合' do
      it 'エラーメッセージを返すこと' do
        entry.update(response: '既存のフィードバック')
        result = service.generate_ai_feedback
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('AIからのコメントは既に生成済みです。')
      end
    end

    context '新規フィードバックを生成する場合' do
      it 'フィードバックを生成して保存すること' do
        allow(AiFeedbackGenerator).to receive(:call).and_return('新しいフィードバック')
        
        result = service.generate_ai_feedback
        
        expect(result[:success]).to be true
        expect(result[:feedback]).to eq('新しいフィードバック')
        expect(result[:message]).to eq('AIからのコメントを追加しました。')
        entry.reload
        expect(entry.response).to eq('新しいフィードバック')
      end
    end
  end

  describe '#add_vocabulary' do
    let(:service) { EntryService.new(user, {}, entry) }

    context '有効なパラメータの場合' do
      it '単語を追加できること' do
        allow(VocabularyService).to receive(:add_from_entry).and_return({
          success: true,
          vocabulary: build(:vocabulary),
          message: '単語を登録しました'
        })

        result = service.add_vocabulary(word: 'test', meaning: 'テスト')
        
        expect(result[:success]).to be true
        expect(result[:message]).to eq('単語を登録しました')
      end
    end

    context 'エントリーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = EntryService.new(user, {}, nil)
        result = service.add_vocabulary(word: 'test', meaning: 'テスト')
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('エントリーが見つかりません。')
      end
    end

    context 'VocabularyServiceがエラーを返す場合' do
      it 'エラーメッセージを返すこと' do
        allow(VocabularyService).to receive(:add_from_entry).and_return({
          success: false,
          error: '単語の登録に失敗しました'
        })

        result = service.add_vocabulary(word: '', meaning: '')
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('単語の登録に失敗しました')
      end
    end
  end

  describe '#get_statistics' do
    let(:service) { EntryService.new(user, {}) }

    before do
      3.times do |i|
        create(:entry, user: user, posted_on: Date.today - i.days)
      end
      create_list(:vocabulary, 5, user: user, mastered: true)
      create_list(:vocabulary, 3, user: user, mastered: false)
    end

    it 'ユーザーの統計情報を取得できること' do
      result = service.get_statistics
      
      expect(result[:success]).to be true
      expect(result[:statistics][:total_entries]).to eq(3)
      expect(result[:statistics][:total_vocabularies]).to eq(8)
      expect(result[:statistics][:mastered_vocabularies]).to eq(5)
      expect(result[:statistics]).to have_key(:learning_streak)
      expect(result[:statistics]).to have_key(:most_used_words)
    end

    context 'ユーザーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = EntryService.new(nil, {})
        result = service.get_statistics
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('ユーザーが見つかりません。')
      end
    end
  end

  describe '#calculate_learning_streak (private)' do
    let(:service) { EntryService.new(user, {}) }

    it '連続投稿日数を計算できること' do
      create(:entry, user: user, posted_on: Date.current)
      create(:entry, user: user, posted_on: Date.current - 1.day)
      create(:entry, user: user, posted_on: Date.current - 2.days)
      
      entries = user.entries
      streak = service.send(:calculate_learning_streak, entries)
      
      expect(streak).to eq(3)
    end

    it 'エントリーが空の場合は0を返すこと' do
      streak = service.send(:calculate_learning_streak, Entry.none)
      expect(streak).to eq(0)
    end
  end
end

