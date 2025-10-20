require 'rails_helper'

RSpec.describe UserService, type: :service do
  let(:user) { create(:user) }
  let(:valid_user_params) { { nickname: 'TestUser', email: 'test@example.com', password: 'password123', password_confirmation: 'password123' } }
  let(:invalid_user_params) { { nickname: '', email: 'invalid', password: '123' } }

  describe '.create_user' do
    context '有効なパラメータの場合' do
      it 'ユーザーを作成できること' do
        result = UserService.create_user(valid_user_params)
        
        expect(result[:success]).to be true
        expect(result[:user]).to be_persisted
        expect(result[:user].nickname).to eq('TestUser')
        expect(result[:message]).to eq('アカウントを作成しました。')
      end

      it 'ユーザー数が増えること' do
        expect {
          UserService.create_user(valid_user_params)
        }.to change(User, :count).by(1)
      end
    end

    context '無効なパラメータの場合' do
      it 'ユーザーが作成されないこと' do
        result = UserService.create_user(invalid_user_params)
        
        expect(result[:success]).to be false
        expect(result[:user]).not_to be_persisted
        expect(result[:errors]).to be_present
        expect(result[:message]).to eq('アカウントの作成に失敗しました。')
      end
    end
  end

  describe '.update_user' do
    context '有効なパラメータの場合' do
      it 'ユーザー情報を更新できること' do
        result = UserService.update_user(user: user, user_params: { nickname: 'UpdatedName' })
        
        expect(result[:success]).to be true
        expect(result[:user].nickname).to eq('UpdatedName')
        expect(result[:message]).to eq('プロフィールを更新しました。')
      end
    end

    context '無効なパラメータの場合' do
      it 'ユーザー情報が更新されないこと' do
        original_nickname = user.nickname
        result = UserService.update_user(user: user, user_params: { nickname: '' })
        
        expect(result[:success]).to be false
        user.reload
        expect(user.nickname).to eq(original_nickname)
        expect(result[:message]).to eq('プロフィールの更新に失敗しました。')
      end
    end

    context 'ユーザーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        result = UserService.update_user(user: nil, user_params: { nickname: 'Test' })
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('ユーザーが見つかりません。')
      end
    end
  end

  describe '.get_user_statistics' do
    before do
      # エントリーを作成（連続3日間）
      create(:entry, user: user, posted_on: Date.current)
      create(:entry, user: user, posted_on: Date.current - 1.day)
      create(:entry, user: user, posted_on: Date.current - 2.days)
      
      # 単語を作成
      create_list(:vocabulary, 5, user: user, mastered: true)
      create_list(:vocabulary, 3, user: user, mastered: false)
    end

    it 'ユーザーの統計情報を取得できること' do
      result = UserService.get_user_statistics(user: user)
      
      expect(result[:success]).to be true
      expect(result[:statistics][:user][:nickname]).to eq(user.nickname)
      expect(result[:statistics][:entries][:total_count]).to eq(3)
      expect(result[:statistics][:entries][:current_streak]).to eq(3)
      expect(result[:statistics][:vocabularies][:total_count]).to eq(8)
      expect(result[:statistics][:vocabularies][:mastered_count]).to eq(5)
      expect(result[:statistics][:vocabularies][:mastery_rate]).to eq(62.5)
      expect(result[:statistics][:achievements]).to be_an(Array)
    end

    context 'ユーザーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        result = UserService.get_user_statistics(user: nil)
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('ユーザーが見つかりません。')
      end
    end
  end

  describe '.get_learning_progress' do
    before do
      10.times do |i|
        create(:entry, user: user, posted_on: Date.today - i.days)
      end
      create_list(:vocabulary, 25, user: user, mastered: true)
      create_list(:vocabulary, 25, user: user, mastered: false)
    end

    it '学習の進捗情報を取得できること' do
      result = UserService.get_learning_progress(user: user)
      
      expect(result[:success]).to be true
      expect(result[:progress][:learning_level]).to eq('学習中')
      expect(result[:progress][:streak_info]).to have_key(:current_streak)
      expect(result[:progress][:streak_info][:streak_goal]).to eq(30)
      expect(result[:progress][:vocabulary_progress][:total_words]).to eq(50)
      expect(result[:progress][:vocabulary_progress][:mastered_words]).to eq(25)
      expect(result[:progress][:vocabulary_progress][:mastery_percentage]).to eq(50.0)
      expect(result[:progress][:writing_progress][:total_entries]).to eq(10)
    end

    context 'ユーザーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        result = UserService.get_learning_progress(user: nil)
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('ユーザーが見つかりません。')
      end
    end
  end

  describe '.get_motivation_message' do
    context '新規ユーザーの場合' do
      it 'ウェルカムメッセージを返すこと' do
        result = UserService.get_motivation_message(user: user)
        
        expect(result[:success]).to be true
        expect(result[:message]).to include('Welcome')
        expect(result[:message]).to include(user.nickname)
        expect(result[:learning_level]).to eq('初心者')
      end
    end

    context '最近投稿したユーザーの場合' do
      it 'エンカレッジメッセージを返すこと' do
        create(:entry, user: user, posted_on: Date.current)
        
        result = UserService.get_motivation_message(user: user)
        
        expect(result[:success]).to be true
        expect(result[:message]).to be_a(String)
        expect(result[:message]).not_to be_empty
      end
    end

    context 'ユーザーがnilの場合' do
      it 'エラーメッセージを返すこと' do
        result = UserService.get_motivation_message(user: nil)
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('ユーザーが見つかりません。')
      end
    end
  end

  describe '#calculate_learning_level (private)' do
    let(:service) { UserService.new({}, user) }

    it '初心者レベルを正しく判定すること' do
      expect(service.send(:calculate_learning_level, 0)).to eq('初心者')
      expect(service.send(:calculate_learning_level, 4)).to eq('初心者')
    end

    it '学習中レベルを正しく判定すること' do
      expect(service.send(:calculate_learning_level, 5)).to eq('学習中')
      expect(service.send(:calculate_learning_level, 19)).to eq('学習中')
    end

    it '中級者レベルを正しく判定すること' do
      expect(service.send(:calculate_learning_level, 20)).to eq('中級者')
      expect(service.send(:calculate_learning_level, 49)).to eq('中級者')
    end

    it '上級者レベルを正しく判定すること' do
      expect(service.send(:calculate_learning_level, 50)).to eq('上級者')
      expect(service.send(:calculate_learning_level, 99)).to eq('上級者')
    end

    it 'エキスパートレベルを正しく判定すること' do
      expect(service.send(:calculate_learning_level, 100)).to eq('エキスパート')
      expect(service.send(:calculate_learning_level, 200)).to eq('エキスパート')
    end
  end

  describe '#calculate_current_streak (private)' do
    let(:service) { UserService.new({}, user) }

    it '連続投稿日数を正しく計算すること' do
      create(:entry, user: user, posted_on: Date.current)
      create(:entry, user: user, posted_on: Date.current - 1.day)
      create(:entry, user: user, posted_on: Date.current - 2.days)
      
      entries = user.entries
      streak = service.send(:calculate_current_streak, entries)
      
      expect(streak).to eq(3)
    end

    it 'エントリーが空の場合は0を返すこと' do
      streak = service.send(:calculate_current_streak, [])
      expect(streak).to eq(0)
    end

    it '投稿が途切れている場合は正しく計算すること' do
      create(:entry, user: user, posted_on: Date.current)
      create(:entry, user: user, posted_on: Date.current - 1.day)
      create(:entry, user: user, posted_on: Date.current - 5.days) # 途切れている
      
      entries = user.entries
      streak = service.send(:calculate_current_streak, entries)
      
      expect(streak).to eq(2)
    end
  end

  describe '#calculate_longest_streak (private)' do
    let(:service) { UserService.new({}, user) }

    it '最長連続投稿日数を正しく計算すること' do
      # 3日連続
      create(:entry, user: user, posted_on: Date.current - 10.days)
      create(:entry, user: user, posted_on: Date.current - 11.days)
      create(:entry, user: user, posted_on: Date.current - 12.days)
      
      # 5日連続（最長）
      create(:entry, user: user, posted_on: Date.current)
      create(:entry, user: user, posted_on: Date.current - 1.day)
      create(:entry, user: user, posted_on: Date.current - 2.days)
      create(:entry, user: user, posted_on: Date.current - 3.days)
      create(:entry, user: user, posted_on: Date.current - 4.days)
      
      entries = user.entries
      longest = service.send(:calculate_longest_streak, entries)
      
      expect(longest).to eq(5)
    end

    it 'エントリーが空の場合は0を返すこと' do
      longest = service.send(:calculate_longest_streak, [])
      expect(longest).to eq(0)
    end
  end

  describe '#get_achievements (private)' do
    let(:service) { UserService.new({}, user) }

    it '初回投稿の実績を取得すること' do
      create(:entry, user: user)
      entries = user.entries
      vocabularies = user.vocabularies
      
      achievements = service.send(:get_achievements, entries, vocabularies)
      
      expect(achievements).to include('初回投稿')
    end

    it '10日間継続の実績を取得すること' do
      10.times do |i|
        create(:entry, user: user, posted_on: Date.today - i.days)
      end
      entries = user.entries
      vocabularies = user.vocabularies
      
      achievements = service.send(:get_achievements, entries, vocabularies)
      
      expect(achievements).to include('10日間継続')
    end

    it '単語登録の実績を取得すること' do
      create(:vocabulary, user: user)
      entries = user.entries
      vocabularies = user.vocabularies
      
      achievements = service.send(:get_achievements, entries, vocabularies)
      
      expect(achievements).to include('初回単語登録')
    end

    it '10単語マスターの実績を取得すること' do
      create_list(:vocabulary, 10, user: user, mastered: true)
      entries = user.entries
      vocabularies = user.vocabularies
      
      achievements = service.send(:get_achievements, entries, vocabularies)
      
      expect(achievements).to include('10単語マスター')
    end
  end
end

