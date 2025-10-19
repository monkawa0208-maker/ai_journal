require 'rails_helper'

RSpec.describe Vocabulary, type: :model do
  # 関連付けのテスト
  describe 'associations' do
    it 'userに属する' do
      vocabulary = Vocabulary.reflect_on_association(:user)
      expect(vocabulary.macro).to eq(:belongs_to)
    end

    it 'entry_vocabulariesを持つ' do
      vocabulary = Vocabulary.reflect_on_association(:entry_vocabularies)
      expect(vocabulary.macro).to eq(:has_many)
      expect(vocabulary.options[:dependent]).to eq(:destroy)
    end

    it 'entriesをentry_vocabularies経由で持つ' do
      vocabulary = Vocabulary.reflect_on_association(:entries)
      expect(vocabulary.macro).to eq(:has_many)
      expect(vocabulary.options[:through]).to eq(:entry_vocabularies)
    end
  end

  # バリデーションのテスト
  describe 'validations' do
    let(:user) { create(:user) }

    it 'wordが必須' do
      vocabulary = build(:vocabulary, user: user, word: nil)
      expect(vocabulary).not_to be_valid
      expect(vocabulary.errors[:word]).to be_present
    end

    it 'meaningが必須' do
      vocabulary = build(:vocabulary, user: user, meaning: nil)
      expect(vocabulary).not_to be_valid
      expect(vocabulary.errors[:meaning]).to be_present
    end

    it 'wordが255文字以下' do
      vocabulary = build(:vocabulary, user: user, word: 'a' * 256)
      expect(vocabulary).not_to be_valid
      expect(vocabulary.errors[:word]).to be_present
    end
    
    context 'uniqueness' do
      it '同一ユーザーが同じ単語を重複登録できない' do
        create(:vocabulary, user: user, word: 'grateful')
        duplicate_vocabulary = build(:vocabulary, user: user, word: 'grateful')
        expect(duplicate_vocabulary).not_to be_valid
        expect(duplicate_vocabulary.errors[:word]).to include('は既に登録されています')
      end

      it '異なるユーザーは同じ単語を登録できる' do
        another_user = create(:user)
        create(:vocabulary, user: user, word: 'grateful')
        duplicate_vocabulary = build(:vocabulary, user: another_user, word: 'grateful')
        expect(duplicate_vocabulary).to be_valid
      end
    end
  end

  # スコープのテスト
  describe 'scopes' do
    let(:user) { create(:user) }
    
    before do
      @vocab1 = create(:vocabulary, user: user, word: 'grateful', created_at: 2.days.ago)
      @vocab2 = create(:vocabulary, user: user, word: 'happy', created_at: 1.day.ago, mastered: true)
      @vocab3 = create(:vocabulary, user: user, word: 'wonderful', favorited: true)
    end

    describe '.recent' do
      it '作成日時の降順で取得する' do
        expect(user.vocabularies.recent).to eq([@vocab3, @vocab2, @vocab1])
      end
    end

    describe '.alphabetical' do
      it 'アルファベット順で取得する' do
        expect(user.vocabularies.alphabetical).to eq([@vocab1, @vocab2, @vocab3])
      end
    end

    describe '.mastered' do
      it '習得済みの単語のみ取得する' do
        expect(user.vocabularies.mastered).to eq([@vocab2])
      end
    end

    describe '.unmastered' do
      it '未習得の単語のみ取得する' do
        expect(user.vocabularies.unmastered).to contain_exactly(@vocab1, @vocab3)
      end
    end

    describe '.favorited' do
      it 'お気に入りの単語のみ取得する' do
        expect(user.vocabularies.favorited).to eq([@vocab3])
      end
    end

    describe '.search_by_word' do
      it '部分一致で単語を検索できる' do
        expect(user.vocabularies.search_by_word('grat')).to eq([@vocab1])
      end

      it '検索キーワードがnilの場合は全件取得する' do
        expect(user.vocabularies.search_by_word(nil).count).to eq(3)
      end
    end
  end

  # メソッドのテスト
  describe '#toggle_mastered!' do
    let(:vocabulary) { create(:vocabulary, mastered: false) }

    it '習得済みフラグを切り替える' do
      expect { vocabulary.toggle_mastered! }.to change { vocabulary.mastered }.from(false).to(true)
    end

    it '再度実行すると元に戻る' do
      vocabulary.toggle_mastered!
      expect { vocabulary.toggle_mastered! }.to change { vocabulary.mastered }.from(true).to(false)
    end
  end

  describe '#toggle_favorited!' do
    let(:vocabulary) { create(:vocabulary, favorited: false) }

    it 'お気に入りフラグを切り替える' do
      expect { vocabulary.toggle_favorited! }.to change { vocabulary.favorited }.from(false).to(true)
    end

    it '再度実行すると元に戻る' do
      vocabulary.toggle_favorited!
      expect { vocabulary.toggle_favorited! }.to change { vocabulary.favorited }.from(true).to(false)
    end
  end

  # 日記との関連付けテスト
  describe 'entry associations' do
    let(:user) { create(:user) }
    let(:vocabulary) { create(:vocabulary, user: user) }
    let(:entry1) { create(:entry, user: user) }
    let(:entry2) { create(:entry, user: user, posted_on: Date.current - 1.day) }

    it '複数の日記に関連付けできる' do
      vocabulary.entries << entry1
      vocabulary.entries << entry2
      expect(vocabulary.entries.count).to eq(2)
      expect(vocabulary.entries).to include(entry1, entry2)
    end

    it '日記から単語にアクセスできる' do
      vocabulary.entries << entry1
      expect(entry1.vocabularies).to include(vocabulary)
    end

    it '単語を削除すると関連付けも削除される' do
      vocabulary.entries << entry1
      expect { vocabulary.destroy }.to change { EntryVocabulary.count }.by(-1)
    end
  end
end
