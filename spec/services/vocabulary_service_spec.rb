require 'rails_helper'

RSpec.describe VocabularyService, type: :service do
  let(:user) { create(:user) }
  let(:vocabulary) { create(:vocabulary, user: user) }
  let(:entry) { create(:entry, user: user) }
  let(:valid_params) { { word: 'grateful', meaning: '感謝している' } }
  let(:invalid_params) { { word: '', meaning: '' } }

  describe '.add_from_entry' do
    context '新規単語の場合' do
      it '単語を作成できること' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: 'テスト',
          entry_id: entry.id
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabulary]).to be_persisted
        expect(result[:vocabulary].word).to eq('test')
        expect(result[:is_new]).to be true
        expect(result[:message]).to eq('単語を登録しました')
      end

      it '日記と関連付けされること' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: 'テスト',
          entry_id: entry.id
        )
        
        expect(result[:vocabulary].entries).to include(entry)
      end

      it 'entry_idがない場合でも登録できること' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: 'テスト'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabulary]).to be_persisted
      end
    end

    context '既存の単語の場合' do
      let!(:existing_vocab) { create(:vocabulary, user: user, word: 'test', meaning: '古い意味') }

      it '意味を更新できること' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: '新しい意味',
          entry_id: entry.id
        )
        
        expect(result[:success]).to be true
        expect(result[:is_new]).to be false
        expect(result[:vocabulary].meaning).to eq('新しい意味')
        expect(result[:message]).to eq('単語を更新しました')
      end

      it '新しい日記との関連付けを追加できること' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: '新しい意味',
          entry_id: entry.id
        )
        
        expect(result[:vocabulary].entries).to include(entry)
      end
    end

    context '無効なパラメータの場合' do
      it 'エラーメッセージを返すこと' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: '',
          meaning: ''
        )
        
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end

    context '存在しないentry_idが渡された場合' do
      it 'エラーメッセージを返すこと' do
        result = VocabularyService.add_from_entry(
          user: user,
          word: 'test',
          meaning: 'テスト',
          entry_id: 99999
        )
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq('日記が見つかりません')
      end
    end
  end

  describe '.create_vocabulary' do
    context '有効なパラメータの場合' do
      it '単語を作成できること' do
        result = VocabularyService.create_vocabulary(
          user: user,
          vocabulary_params: valid_params
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabulary]).to be_persisted
        expect(result[:vocabulary].word).to eq('grateful')
        expect(result[:message]).to eq('単語を登録しました')
      end
    end

    context '無効なパラメータの場合' do
      it '単語が作成されないこと' do
        result = VocabularyService.create_vocabulary(
          user: user,
          vocabulary_params: invalid_params
        )
        
        expect(result[:success]).to be false
        expect(result[:vocabulary]).not_to be_persisted
        expect(result[:errors]).to be_present
        expect(result[:message]).to eq('単語の登録に失敗しました')
      end
    end
  end

  describe '.update_vocabulary' do
    context '有効なパラメータの場合' do
      it '単語を更新できること' do
        result = VocabularyService.update_vocabulary(
          vocabulary: vocabulary,
          vocabulary_params: { meaning: '更新された意味' }
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabulary].meaning).to eq('更新された意味')
        expect(result[:message]).to eq('単語を更新しました')
      end
    end

    context '無効なパラメータの場合' do
      it '単語が更新されないこと' do
        original_meaning = vocabulary.meaning
        result = VocabularyService.update_vocabulary(
          vocabulary: vocabulary,
          vocabulary_params: { word: '' }
        )
        
        expect(result[:success]).to be false
        vocabulary.reload
        expect(vocabulary.meaning).to eq(original_meaning)
        expect(result[:message]).to eq('単語の更新に失敗しました')
      end
    end

    context '単語がnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = VocabularyService.new(user, valid_params[:word], valid_params[:meaning], nil, nil)
        result = service.update_vocabulary(valid_params)
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('単語が見つかりません。')
      end
    end
  end

  describe '.destroy_vocabulary' do
    let!(:vocab_to_delete) { create(:vocabulary, user: user, word: 'test') }

    it '単語を削除できること' do
      result = VocabularyService.destroy_vocabulary(vocabulary: vocab_to_delete)
      
      expect(result[:success]).to be true
      expect(result[:message]).to eq('単語「test」を削除しました。')
      expect { vocab_to_delete.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context '単語がnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = VocabularyService.new(user, nil, nil, nil, nil)
        result = service.destroy_vocabulary
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('単語が見つかりません。')
      end
    end
  end

  describe '.toggle_mastered' do
    let(:vocabulary) { create(:vocabulary, user: user, mastered: false) }

    it '習得済みフラグをトグルできること' do
      result = VocabularyService.toggle_mastered(vocabulary: vocabulary)
      
      expect(result[:success]).to be true
      expect(result[:mastered]).to be true
      expect(result[:message]).to eq('習得済みにしました')
      vocabulary.reload
      expect(vocabulary.mastered).to be true
    end

    it '再度実行すると元に戻ること' do
      VocabularyService.toggle_mastered(vocabulary: vocabulary)
      result = VocabularyService.toggle_mastered(vocabulary: vocabulary)
      
      expect(result[:success]).to be true
      expect(result[:mastered]).to be false
      expect(result[:message]).to eq('未習得にしました')
      vocabulary.reload
      expect(vocabulary.mastered).to be false
    end

    context '単語がnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = VocabularyService.new(user, nil, nil, nil, nil)
        result = service.toggle_mastered
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('単語が見つかりません。')
      end
    end
  end

  describe '.toggle_favorited' do
    let(:vocabulary) { create(:vocabulary, user: user, favorited: false) }

    it 'お気に入りフラグをトグルできること' do
      result = VocabularyService.toggle_favorited(vocabulary: vocabulary)
      
      expect(result[:success]).to be true
      expect(result[:favorited]).to be true
      expect(result[:message]).to eq('お気に入りにしました')
      vocabulary.reload
      expect(vocabulary.favorited).to be true
    end

    it '再度実行すると元に戻ること' do
      VocabularyService.toggle_favorited(vocabulary: vocabulary)
      result = VocabularyService.toggle_favorited(vocabulary: vocabulary)
      
      expect(result[:success]).to be true
      expect(result[:favorited]).to be false
      expect(result[:message]).to eq('お気に入りを解除しました')
      vocabulary.reload
      expect(vocabulary.favorited).to be false
    end

    context '単語がnilの場合' do
      it 'エラーメッセージを返すこと' do
        service = VocabularyService.new(user, nil, nil, nil, nil)
        result = service.toggle_favorited
        
        expect(result[:success]).to be false
        expect(result[:message]).to eq('単語が見つかりません。')
      end
    end
  end

  describe '.search_vocabularies' do
    before do
      create(:vocabulary, user: user, word: 'grateful', meaning: '感謝している')
      create(:vocabulary, user: user, word: 'happy', meaning: '幸せな', mastered: true)
      create(:vocabulary, user: user, word: 'wonderful', meaning: '素晴らしい', favorited: true)
    end

    context '検索語がある場合' do
      it '部分一致で検索できること' do
        result = VocabularyService.search_vocabularies(
          user: user,
          search_term: 'grat'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(1)
        expect(result[:vocabularies].first.word).to eq('grateful')
      end
    end

    context 'フィルタリング' do
      it '習得済みでフィルタリングできること' do
        result = VocabularyService.search_vocabularies(
          user: user,
          search_term: nil,
          filter: 'mastered'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(1)
        expect(result[:vocabularies].first.word).to eq('happy')
      end

      it '未習得でフィルタリングできること' do
        result = VocabularyService.search_vocabularies(
          user: user,
          search_term: nil,
          filter: 'unmastered'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(2)
      end

      it 'お気に入りでフィルタリングできること' do
        result = VocabularyService.search_vocabularies(
          user: user,
          search_term: nil,
          filter: 'favorited'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(1)
        expect(result[:vocabularies].first.word).to eq('wonderful')
      end
    end

    it '検索語とフィルタを組み合わせられること' do
      result = VocabularyService.search_vocabularies(
        user: user,
        search_term: 'ha',
        filter: 'mastered'
      )
      
      expect(result[:success]).to be true
      expect(result[:vocabularies].count).to eq(1)
      expect(result[:vocabularies].first.word).to eq('happy')
    end
  end

  describe '.get_flashcard_vocabularies' do
    context '単語が存在する場合' do
      before do
        create_list(:vocabulary, 5, user: user, mastered: false)
        create_list(:vocabulary, 3, user: user, mastered: true)
      end

      it '単語一覧を取得できること' do
        result = VocabularyService.get_flashcard_vocabularies(user: user)
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(8)
      end

      it '未習得のみでフィルタリングできること' do
        result = VocabularyService.get_flashcard_vocabularies(
          user: user,
          filter: 'unmastered'
        )
        
        expect(result[:success]).to be true
        expect(result[:vocabularies].count).to eq(5)
      end
    end

    context '単語が存在しない場合' do
      it 'エラーメッセージを返すこと' do
        result = VocabularyService.get_flashcard_vocabularies(user: user)
        
        expect(result[:success]).to be false
        expect(result[:vocabularies]).to eq([])
        expect(result[:message]).to eq('復習する単語がありません')
      end
    end
  end

  describe '#get_statistics (private)' do
    let(:service) { VocabularyService.new(user) }

    before do
      create_list(:vocabulary, 10, user: user, mastered: true)
      create_list(:vocabulary, 5, user: user, mastered: false, favorited: true)
    end

    it '単語の統計情報を取得できること' do
      result = service.get_statistics
      
      expect(result[:success]).to be true
      expect(result[:statistics][:total_vocabularies]).to eq(15)
      expect(result[:statistics][:mastered_vocabularies]).to eq(10)
      expect(result[:statistics][:favorited_vocabularies]).to eq(5)
      expect(result[:statistics][:mastery_rate]).to eq(66.7)
    end
  end
end

