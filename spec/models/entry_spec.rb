require 'rails_helper'

RSpec.describe Entry, type: :model do
  
  before do
    @entry = FactoryBot.build(:entry)
  end

  # 正常系：有効なエントリーが作成できること
  describe 'バリデーション' do
    it '有効なエントリーであること' do
      expect(@entry).to be_valid
    end

    # titleのバリデーションテスト
    describe 'title' do
      it 'titleが空の場合は無効であること' do
        @entry.title = nil
        @entry.valid?
        expect(@entry.errors.full_messages).to include('タイトルを入力してください')
      end

      it 'titleが100文字以内であれば有効であること' do
        @entry.title = 'a' * 100
        expect(@entry).to be_valid
      end

      it 'titleが101文字以上の場合は無効であること' do
        @entry.title = 'a' * 101
        @entry.valid?
        expect(@entry.errors.full_messages).to include('タイトルは100文字以内で入力してください')
      end
    end

    # contentのバリデーションテスト
    describe 'content' do
      it 'contentが空の場合は無効であること' do
        @entry.content = nil
        @entry.valid?
        expect(@entry.errors.full_messages).to include('本文を入力してください')
      end

      it 'contentが10,000文字以内であれば有効であること' do
        @entry.content = 'a' * 10_000
        expect(@entry).to be_valid
      end

      it 'contentが10,001文字以上の場合は無効であること' do
        @entry.content = 'a' * 10_001
        @entry.valid?
        expect(@entry.errors.full_messages).to include('本文は10000文字以内で入力してください')
      end
    end

    # posted_onのバリデーションテスト
    describe 'posted_on' do
      it 'posted_onが空の場合は無効であること' do
        @entry.posted_on = nil
        @entry.valid?
        expect(@entry.errors.full_messages).to include('日付を入力してください')
      end

      it '同じユーザーで同じ日付のエントリーは作成できないこと（1日1件ルール）' do
        user = FactoryBot.create(:user)
        FactoryBot.create(:entry, user: user, posted_on: Date.today)
        @entry.user = user
        @entry.posted_on = Date.today
        
        @entry.valid?
        expect(@entry.errors.full_messages).to include('すでにこの日の日記は作成済みです')
      end

      it '異なるユーザーであれば同じ日付のエントリーを作成できること' do
        user1 = FactoryBot.create(:user)
        user2 = FactoryBot.create(:user)
        FactoryBot.create(:entry, user: user1, posted_on: Date.today)
        @entry.user = user2
        @entry.posted_on = Date.today
        
        expect(@entry).to be_valid
      end

      it '同じユーザーで異なる日付のエントリーを作成できること' do
        user = FactoryBot.create(:user)
        FactoryBot.create(:entry, user: user, posted_on: Date.today)
        @entry.user = user
        @entry.posted_on = Date.yesterday
        
        expect(@entry).to be_valid
      end
    end

    # responseのバリデーションテスト
    describe 'response' do
      it 'responseが空でも有効であること' do
        @entry.response = nil
        expect(@entry).to be_valid
      end

      it 'responseが10,000文字以内であれば有効であること' do
        @entry.response = 'a' * 10_000
        expect(@entry).to be_valid
      end

      it 'responseが10,001文字以上の場合は無効であること' do
        @entry.response = 'a' * 10_001
        @entry.valid?
        expect(@entry.errors.full_messages).to include('Responseは10000文字以内で入力してください')
      end
    end
  end

  # アソシエーションのテスト
  describe 'アソシエーション' do
    it 'userが紐づいていること' do
      expect(@entry).to respond_to(:user)
    end

    it 'userが存在しない場合は無効であること' do
      @entry.user = nil
      expect(@entry).not_to be_valid
    end
  end

  # スコープのテスト
  describe 'スコープ' do
    it 'recentスコープで新しい順に取得できること' do
      user = FactoryBot.create(:user)
      entry1 = FactoryBot.create(:entry, user: user, posted_on: Date.today - 2.days)
      entry2 = FactoryBot.create(:entry, user: user, posted_on: Date.today)
      entry3 = FactoryBot.create(:entry, user: user, posted_on: Date.today - 1.day)
      
      recent_entries = Entry.recent
      expect(recent_entries.to_a).to eq([entry2, entry3, entry1])
    end

    it 'this_monthスコープで今月のエントリーのみ取得できること' do
      user = FactoryBot.create(:user)
      entry_this_month = FactoryBot.create(:entry, user: user, posted_on: Date.today)
      entry_last_month = FactoryBot.create(:entry, user: user, posted_on: Date.today - 1.month)
      
      this_month_entries = Entry.this_month
      expect(this_month_entries).to include(entry_this_month)
      expect(this_month_entries).not_to include(entry_last_month)
    end
  end

  # Active Storageのテスト
  describe 'Active Storage' do
    it '画像を添付できること' do
      entry = FactoryBot.create(:entry)
      expect(entry).to respond_to(:image)
    end
  end
end
