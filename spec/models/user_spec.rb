require 'rails_helper'

RSpec.describe User, type: :model do
  
  before do
    @user = FactoryBot.build(:user)
  end

  # 正常系：有効なユーザーが作成できること
  describe 'バリデーション' do
    it '有効なユーザーであること' do
      expect(@user).to be_valid
    end

    # nicknameのバリデーションテスト
    describe 'nickname' do
      it 'nicknameが空の場合は無効であること' do
        @user.nickname = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:nickname]).to be_present
      end

      it 'nicknameが30文字以内であれば有効であること' do
        @user.nickname = 'a' * 30
        expect(@user).to be_valid
      end

      it 'nicknameが31文字以上の場合は無効であること' do
        @user.nickname = 'a' * 31
        expect(@user).not_to be_valid
        expect(@user.errors[:nickname]).to be_present
      end
    end

    # emailのバリデーションテスト（Deviseによる）
    describe 'email' do
      it 'emailが空の場合は無効であること' do
        @user.email = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to be_present
      end

      it '重複したemailの場合は無効であること' do
        FactoryBot.create(:user, email: 'test@example.com')
        @user.email = 'test@example.com'
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to be_present
      end

      it '無効な形式のemailの場合は無効であること' do
        @user.email = 'invalid_email'
        expect(@user).not_to be_valid
        expect(@user.errors[:email]).to be_present
      end
    end

    # passwordのバリデーションテスト（Deviseによる）
    describe 'password' do
      it 'passwordが空の場合は無効であること' do
        @user.password = nil
        @user.password_confirmation = nil
        expect(@user).not_to be_valid
        expect(@user.errors[:password]).to be_present
      end

      it 'passwordが6文字未満の場合は無効であること' do
        @user.password = '12345'
        @user.password_confirmation = '12345'
        expect(@user).not_to be_valid
        expect(@user.errors[:password]).to be_present
      end

      it 'passwordとpassword_confirmationが一致しない場合は無効であること' do
        @user.password = 'password123'
        @user.password_confirmation = 'different'
        expect(@user).not_to be_valid
        expect(@user.errors[:password_confirmation]).to be_present
      end
    end
  end

  # アソシエーションのテスト
  describe 'アソシエーション' do
    it 'ユーザーが削除されると、紐づくエントリーも削除されること' do
      user = FactoryBot.create(:user)
      FactoryBot.create(:entry, user: user)
      FactoryBot.create(:entry, user: user, posted_on: Date.yesterday)
      
      expect { user.destroy }.to change { Entry.count }.by(-2)
    end

    it '複数のエントリーを持つことができること' do
      user = FactoryBot.create(:user)
      entry1 = FactoryBot.create(:entry, user: user, posted_on: Date.today)
      entry2 = FactoryBot.create(:entry, user: user, posted_on: Date.yesterday)
      
      expect(user.entries.count).to eq(2)
      expect(user.entries).to include(entry1, entry2)
    end
  end
end
