require 'rails_helper'

RSpec.describe "Vocabularies", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /vocabularies" do
    it "単語一覧ページを表示する" do
      get vocabularies_path
      expect(response).to have_http_status(:success)
    end

    context "検索機能" do
      before do
        create(:vocabulary, user: user, word: 'grateful', meaning: '感謝している')
        create(:vocabulary, user: user, word: 'happy', meaning: '幸せな')
      end

      it "単語で検索できる" do
        get vocabularies_path(search: 'grat')
        expect(response).to have_http_status(:success)
        expect(response.body).to include('grateful')
        expect(response.body).not_to include('happy')
      end
    end

    context "フィルタリング機能" do
      before do
        create(:vocabulary, user: user, word: 'grateful', mastered: true)
        create(:vocabulary, user: user, word: 'happy', mastered: false)
        create(:vocabulary, user: user, word: 'wonderful', favorited: true)
      end

      it "習得済みでフィルタリングできる" do
        get vocabularies_path(filter: 'mastered')
        expect(response).to have_http_status(:success)
      end

      it "未習得でフィルタリングできる" do
        get vocabularies_path(filter: 'unmastered')
        expect(response).to have_http_status(:success)
      end

      it "お気に入りでフィルタリングできる" do
        get vocabularies_path(filter: 'favorited')
        expect(response).to have_http_status(:success)
      end
    end

    context "JSON形式" do
      before do
        create(:vocabulary, user: user, word: 'grateful', meaning: '感謝している')
      end

      it "JSON形式でレスポンスを返す" do
        get vocabularies_path(format: :json)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['vocabularies']).to be_an(Array)
        expect(json_response['vocabularies'].first['word']).to eq('grateful')
      end
    end
  end

  describe "GET /vocabularies/new" do
    it "新規作成フォームを表示する" do
      get new_vocabulary_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /vocabularies" do
    let(:valid_attributes) { { word: 'grateful', meaning: '感謝している' } }
    let(:invalid_attributes) { { word: '', meaning: '' } }

    context "有効なパラメータの場合" do
      it "単語を作成する" do
        expect {
          post vocabularies_path, params: { vocabulary: valid_attributes }
        }.to change(Vocabulary, :count).by(1)
        expect(response).to redirect_to(vocabularies_path)
      end

      it "日記との関連付けができる" do
        entry = create(:entry, user: user)
        post vocabularies_path, params: { vocabulary: valid_attributes, entry_id: entry.id }
        
        vocabulary = Vocabulary.last
        expect(vocabulary.entries).to include(entry)
      end
    end

    context "無効なパラメータの場合" do
      it "単語を作成しない" do
        expect {
          post vocabularies_path, params: { vocabulary: invalid_attributes }
        }.not_to change(Vocabulary, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /vocabularies/add_from_entry" do
    let(:entry) { create(:entry, user: user) }
    let(:valid_params) { { word: 'grateful', meaning: '感謝している', entry_id: entry.id } }

    context "有効なパラメータの場合" do
      it "単語を作成する" do
        expect {
          post add_from_entry_vocabularies_path, params: valid_params
        }.to change(Vocabulary, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['is_new']).to be true
        expect(json_response['message']).to eq('単語を登録しました')
      end

      it "日記と関連付けされる" do
        post add_from_entry_vocabularies_path, params: valid_params
        
        vocabulary = Vocabulary.last
        expect(vocabulary.entries).to include(entry)
      end

      it "entry_idがない場合でも登録できる" do
        expect {
          post add_from_entry_vocabularies_path, params: { word: 'happy', meaning: '幸せな' }
        }.to change(Vocabulary, :count).by(1)
      end
    end

    context "既存の単語の場合" do
      let!(:existing_vocab) { create(:vocabulary, user: user, word: 'grateful', meaning: '感謝している') }

      it "意味を更新する" do
        post add_from_entry_vocabularies_path, params: { 
          word: 'grateful', 
          meaning: '感謝している、ありがたい',
          entry_id: entry.id 
        }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['is_new']).to be false
        expect(json_response['message']).to eq('単語を更新しました')
        
        existing_vocab.reload
        expect(existing_vocab.meaning).to eq('感謝している、ありがたい')
      end

      it "新しい日記との関連付けを追加する" do
        expect {
          post add_from_entry_vocabularies_path, params: valid_params
        }.to change { existing_vocab.entries.count }.by(1)
      end
    end

    context "無効なパラメータの場合" do
      it "単語が空の場合はエラーを返す" do
        post add_from_entry_vocabularies_path, params: { word: '', meaning: '意味' }
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('単語と意味が必要です')
      end

      it "意味が空の場合はエラーを返す" do
        post add_from_entry_vocabularies_path, params: { word: 'test', meaning: '' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /vocabularies/:id/edit" do
    let(:vocabulary) { create(:vocabulary, user: user) }

    it "編集フォームを表示する" do
      get edit_vocabulary_path(vocabulary)
      expect(response).to have_http_status(:success)
    end

    it "他ユーザーの単語は編集できない" do
      other_vocabulary = create(:vocabulary, user: other_user)
      get edit_vocabulary_path(other_vocabulary)
      # RecordNotFoundが発生してrescue_fromで処理される
      # 実装によってはリダイレクトまたは404になる
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "PATCH /vocabularies/:id" do
    let(:vocabulary) { create(:vocabulary, user: user, word: 'grateful', meaning: '感謝している') }
    let(:new_attributes) { { word: 'grateful', meaning: '感謝している、ありがたい', mastered: true } }

    it "単語を更新する" do
      patch vocabulary_path(vocabulary), params: { vocabulary: new_attributes }
      
      vocabulary.reload
      expect(vocabulary.meaning).to eq('感謝している、ありがたい')
      expect(vocabulary.mastered).to be true
      expect(response).to redirect_to(vocabularies_path)
    end

    it "他ユーザーの単語は更新できない" do
      other_vocabulary = create(:vocabulary, user: other_user)
      patch vocabulary_path(other_vocabulary), params: { vocabulary: new_attributes }
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "DELETE /vocabularies/:id" do
    let!(:vocabulary) { create(:vocabulary, user: user) }

    it "単語を削除する" do
      expect {
        delete vocabulary_path(vocabulary)
      }.to change(Vocabulary, :count).by(-1)
      expect(response).to redirect_to(vocabularies_path)
    end

    it "他ユーザーの単語は削除できない" do
      other_vocabulary = create(:vocabulary, user: other_user)
      expect {
        delete vocabulary_path(other_vocabulary)
      }.not_to change(Vocabulary, :count)
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "PATCH /vocabularies/:id/toggle_mastered" do
    let(:vocabulary) { create(:vocabulary, user: user, mastered: false) }

    it "習得済みフラグをトグルする" do
      patch toggle_mastered_vocabulary_path(vocabulary)
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['mastered']).to be true
      
      vocabulary.reload
      expect(vocabulary.mastered).to be true
    end

    it "他ユーザーの単語は変更できない" do
      other_vocabulary = create(:vocabulary, user: other_user)
      patch toggle_mastered_vocabulary_path(other_vocabulary)
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "PATCH /vocabularies/:id/toggle_favorited" do
    let(:vocabulary) { create(:vocabulary, user: user, favorited: false) }

    it "お気に入りフラグをトグルする" do
      patch toggle_favorited_vocabulary_path(vocabulary)
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['favorited']).to be true
      
      vocabulary.reload
      expect(vocabulary.favorited).to be true
    end

    it "他ユーザーの単語は変更できない" do
      other_vocabulary = create(:vocabulary, user: other_user)
      patch toggle_favorited_vocabulary_path(other_vocabulary)
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "GET /vocabularies/flashcard" do
    context "単語が存在する場合" do
      before do
        create_list(:vocabulary, 3, user: user)
      end

      it "フラッシュカードページを表示する" do
        get flashcard_vocabularies_path
        expect(response).to have_http_status(:success)
      end

      it "未習得のみでフィルタリングできる" do
        get flashcard_vocabularies_path(filter: 'unmastered')
        expect(response).to have_http_status(:success)
      end
    end

    context "単語が存在しない場合" do
      it "単語一覧へリダイレクトする" do
        get flashcard_vocabularies_path
        expect(response).to redirect_to(vocabularies_path)
        expect(flash[:alert]).to eq('復習する単語がありません')
      end
    end
  end

  # 認証のテスト
  describe "authentication" do
    before do
      sign_out user
    end

    it "未ログインの場合、indexにアクセスできない" do
      get vocabularies_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "未ログインの場合、flashcardにアクセスできない" do
      get flashcard_vocabularies_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
