require 'rails_helper'

RSpec.describe EntryVocabulary, type: :model do
  # 関連付けのテスト
  describe 'associations' do
    it 'entryに属する' do
      entry_vocabulary = EntryVocabulary.reflect_on_association(:entry)
      expect(entry_vocabulary.macro).to eq(:belongs_to)
    end

    it 'vocabularyに属する' do
      entry_vocabulary = EntryVocabulary.reflect_on_association(:vocabulary)
      expect(entry_vocabulary.macro).to eq(:belongs_to)
    end
  end

  # バリデーションのテスト
  describe 'validations' do
    let(:user) { create(:user) }
    let(:entry) { create(:entry, user: user) }
    let(:vocabulary) { create(:vocabulary, user: user) }

    it '有効なファクトリを持つ' do
      entry_vocabulary = build(:entry_vocabulary, entry: entry, vocabulary: vocabulary)
      expect(entry_vocabulary).to be_valid
    end

    context 'uniqueness' do
      it '同じ日記に同じ単語を重複登録できない' do
        create(:entry_vocabulary, entry: entry, vocabulary: vocabulary)
        duplicate = build(:entry_vocabulary, entry: entry, vocabulary: vocabulary)
        expect(duplicate).not_to be_valid
      end

      it '同じ単語を異なる日記に登録できる' do
        another_entry = create(:entry, user: user, posted_on: Date.current - 1.day)
        create(:entry_vocabulary, entry: entry, vocabulary: vocabulary)
        another_ev = build(:entry_vocabulary, entry: another_entry, vocabulary: vocabulary)
        expect(another_ev).to be_valid
      end

      it '同じ日記に異なる単語を登録できる' do
        another_vocabulary = create(:vocabulary, user: user, word: 'happy')
        create(:entry_vocabulary, entry: entry, vocabulary: vocabulary)
        another_ev = build(:entry_vocabulary, entry: entry, vocabulary: another_vocabulary)
        expect(another_ev).to be_valid
      end
    end
  end

  # 関連付けの削除テスト
  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:entry) { create(:entry, user: user) }
    let(:vocabulary) { create(:vocabulary, user: user) }
    let!(:entry_vocabulary) { create(:entry_vocabulary, entry: entry, vocabulary: vocabulary) }

    it '日記を削除すると関連付けも削除される' do
      expect { entry.destroy }.to change { EntryVocabulary.count }.by(-1)
    end

    it '単語を削除すると関連付けも削除される' do
      expect { vocabulary.destroy }.to change { EntryVocabulary.count }.by(-1)
    end

    it '関連付けを削除しても日記と単語は残る' do
      expect {
        entry_vocabulary.destroy
      }.not_to change { Entry.count }
      expect(Entry.exists?(entry.id)).to be true
      expect(Vocabulary.exists?(vocabulary.id)).to be true
    end
  end
end
