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
        @user.valid?
        expect(@user.errors.full_messages).to include('ニックネームを入力してください')
      end

      it 'nicknameが30文字以内であれば有効であること' do
        @user.nickname = 'a' * 30
        expect(@user).to be_valid
      end

      it 'nicknameが31文字以上の場合は無効であること' do
        @user.nickname = 'a' * 31
        @user.valid?
        expect(@user.errors.full_messages).to include('ニックネームは30文字以内で入力してください')
      end
    end

    # emailのバリデーションテスト（Deviseによる）
    describe 'email' do
      it 'emailが空の場合は無効であること' do
        @user.email = nil
        @user.valid?
        expect(@user.errors.full_messages).to include('メールアドレスを入力してください')
      end

      it '重複したemailの場合は無効であること' do
        FactoryBot.create(:user, email: 'test@example.com')
        @user.email = 'test@example.com'
        @user.valid?
        expect(@user.errors.full_messages).to include('メールアドレスはすでに存在します')
      end

      it '無効な形式のemailの場合は無効であること' do
        @user.email = 'invalid_email'
        @user.valid?
        expect(@user.errors.full_messages).to include('メールアドレスは不正な値です')
      end
    end

    # passwordのバリデーションテスト（Deviseによる）
    describe 'password' do
      it 'passwordが空の場合は無効であること' do
        @user.password = nil
        @user.password_confirmation = nil
        @user.valid?
        expect(@user.errors.full_messages).to include('パスワードを入力してください')
      end

      it 'passwordが6文字未満の場合は無効であること' do
        @user.password = '12345'
        @user.password_confirmation = '12345'
        @user.valid?
        expect(@user.errors.full_messages).to include('パスワードは6文字以上で入力してください')
      end

      it 'passwordとpassword_confirmationが一致しない場合は無効であること' do
        @user.password = 'password123'
        @user.password_confirmation = 'different'
        @user.valid?
        expect(@user.errors.full_messages).to include('パスワード（確認）とパスワードの入力が一致しません')
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
