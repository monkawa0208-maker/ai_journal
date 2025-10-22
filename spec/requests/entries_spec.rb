require 'rails_helper'

RSpec.describe "Entries", type: :request do
  
  before do
    @user = FactoryBot.create(:user)
    @other_user = FactoryBot.create(:user)
    @entry = FactoryBot.create(:entry, user: @user, posted_on: Date.today)
    @other_entry = FactoryBot.create(:entry, user: @other_user, posted_on: Date.yesterday)
  end

  describe "GET /entries" do
    context "ログインしていない場合" do
      it "ログインページにリダイレクトすること" do
        get entries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログインしている場合" do
      before do
        sign_in @user
      end

      it "HTML形式でステータス200を返すこと" do
        get entries_path
        expect(response).to have_http_status(:success)
      end

      it "自分のエントリーのみ表示されること" do
        get entries_path
        expect(response.body).to include(@entry.title)
        expect(response.body).not_to include(@other_entry.title)
      end

      it "JSON形式でエントリー一覧を返すこと" do
        get entries_path, params: {}, as: :json
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.first['id']).to eq(@entry.id)
      end
    end
  end

  describe "GET /entries/:id" do
    before do
      sign_in @user
    end

    it "自分のエントリーを表示できること" do
      get entry_path(@entry)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(@entry.title)
    end

    it "他のユーザーのエントリーにはアクセスできないこと" do
      # current_user.entriesスコープで検索されるため、RecordNotFoundが発生する
      # ErrorHandlingモジュールがHTMLリクエストの場合にリダイレクトする
      get entry_path(@other_entry)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /entries/new" do
    before do
      sign_in @user
    end

    it "新規作成フォームを表示すること" do
      get new_entry_path
      expect(response).to have_http_status(:success)
    end

    it "デフォルトで当日の日付が設定されていること" do
      get new_entry_path
      expect(response.body).to include(Date.current.to_s)
    end
  end

  describe "POST /entries" do
    before do
      sign_in @user
    end

    context "有効なパラメータの場合" do
      it "エントリーが作成されること" do
        expect {
          post entries_path, params: {
            entry: {
              title: 'New Entry',
              content: 'New content',
              posted_on: Date.today + 1.day
            }
          }
        }.to change(Entry, :count).by(1)
      end

      it "作成後、詳細ページにリダイレクトすること" do
        post entries_path, params: {
          entry: {
            title: 'New Entry',
            content: 'New content',
            posted_on: Date.today + 1.day
          }
        }
        expect(response).to redirect_to(entry_path(Entry.last))
        expect(flash[:notice]).to eq('日記を投稿しました。')
      end
    end

    context "無効なパラメータの場合" do
      it "エントリーが作成されないこと" do
        expect {
          post entries_path, params: {
            entry: {
              title: '',
              content: 'New content',
              posted_on: Date.today
            }
          }
        }.not_to change(Entry, :count)
      end

      it "新規作成フォームを再表示すること" do
        post entries_path, params: {
          entry: {
            title: '',
            content: 'New content',
            posted_on: Date.today
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /entries/:id/edit" do
    before do
      sign_in @user
    end

    it "編集フォームを表示すること" do
      get edit_entry_path(@entry)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(@entry.title)
    end
  end

  describe "PATCH /entries/:id" do
    before do
      sign_in @user
    end

    context "有効なパラメータの場合" do
      it "エントリーが更新されること" do
        patch entry_path(@entry), params: {
          entry: {
            title: 'Updated Title'
          }
        }
        @entry.reload
        expect(@entry.title).to eq('Updated Title')
      end

      it "更新後、詳細ページにリダイレクトすること" do
        patch entry_path(@entry), params: {
          entry: {
            title: 'Updated Title'
          }
        }
        expect(response).to redirect_to(entry_path(@entry))
        expect(flash[:notice]).to eq('日記を更新しました。')
      end
    end

    context "無効なパラメータの場合" do
      it "エントリーが更新されないこと" do
        original_title = @entry.title
        original_content = @entry.content
        patch entry_path(@entry), params: {
          entry: {
            title: '',
            content: ''
          }
        }
        @entry.reload
        expect(@entry.title).to eq(original_title)
        expect(@entry.content).to eq(original_content)
      end

      it "編集フォームを再表示すること" do
        patch entry_path(@entry), params: {
          entry: {
            title: '',
            content: ''
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /entries/:id" do
    before do
      sign_in @user
    end

    it "エントリーが削除されること" do
      expect {
        delete entry_path(@entry)
      }.to change(Entry, :count).by(-1)
    end

    it "削除後、一覧ページにリダイレクトすること" do
      delete entry_path(@entry)
      expect(response).to redirect_to(entries_path)
      expect(flash[:notice]).to eq('日記を削除しました。')
    end
  end

  describe "POST /entries/translate" do
    before do
      sign_in @user
    end

    context "有効なテキストが渡された場合" do
      it "翻訳結果を返すこと" do
        allow(AiTranslator).to receive(:call).and_return('Hello, this is a test.')
        
        post translate_entries_path, params: { text: 'こんにちは、これはテストです。' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['translation']).to eq('Hello, this is a test.')
      end
    end

    context "テキストが空の場合" do
      it "エラーを返すこと" do
        post translate_entries_path, params: { text: '' }
        
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('翻訳するテキストが入力されていません')
      end
    end

    context "TranslationErrorが発生した場合" do
      it "エラーを返すこと" do
        allow(AiTranslator).to receive(:call).and_raise(AiTranslator::TranslationError, 'Translation failed')
        
        post translate_entries_path, params: { text: 'こんにちは' }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Translation failed')
      end
    end
  end

  describe "POST /entries/preview_feedback" do
    before do
      sign_in @user
    end

    context "有効なパラメータの場合" do
      it "フィードバックを返すこと" do
        allow(AiFeedbackGenerator).to receive(:call).and_return('素晴らしい日記ですね！')
        
        post preview_feedback_entries_path, params: {
          title: 'Test Title',
          content: 'Test Content'
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['response']).to eq('素晴らしい日記ですね！')
      end
    end

    context "本文が空の場合" do
      it "エラーを返すこと" do
        post preview_feedback_entries_path, params: {
          content: ''
        }
        
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('本文を入力してください')
      end
    end

    context "エラーが発生した場合" do
      it "エラーを返すこと" do
        allow(AiFeedbackGenerator).to receive(:call).and_raise(StandardError, 'Feedback generation failed')
        
        post preview_feedback_entries_path, params: {
          content: 'Test Content'
        }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe "POST /entries/:id/generate_feedback" do
    before do
      sign_in @user
    end

    context "JSON形式のリクエストの場合" do
      it "既存のフィードバックがある場合は既存のものを返すこと" do
        @entry.update(response: '既存のフィードバック')
        
        post generate_feedback_entry_path(@entry), as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['response']).to eq('既存のフィードバック')
      end

      it "新規フィードバックを生成して保存すること" do
        # responseがnilのエントリーを新規作成
        entry_without_response = FactoryBot.create(:entry, user: @user, posted_on: Date.today + 2.days, response: nil)
        allow(AiFeedbackGenerator).to receive(:call).and_return('新しいフィードバック')
        
        post generate_feedback_entry_path(entry_without_response), as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['response']).to eq('新しいフィードバック')
        entry_without_response.reload
        expect(entry_without_response.response).to eq('新しいフィードバック')
      end

      it "エラーが発生した場合はエラーを返すこと" do
        entry_without_response = FactoryBot.create(:entry, user: @user, posted_on: Date.today + 3.days, response: nil)
        allow(AiFeedbackGenerator).to receive(:call).and_raise(StandardError, 'Error')
        
        post generate_feedback_entry_path(entry_without_response), as: :json
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('AIからのコメント生成に失敗しました')
      end
    end

    context "HTML形式のリクエストの場合" do
      it "既存のフィードバックがある場合は詳細ページにリダイレクトすること" do
        entry_with_response = FactoryBot.create(:entry, user: @user, posted_on: Date.today + 4.days, response: '既存のフィードバック')
        
        post generate_feedback_entry_path(entry_with_response)
        
        expect(response).to redirect_to(entry_path(entry_with_response))
        expect(flash[:notice]).to eq('AIからのコメントは既に生成済みです。')
      end

      it "新規フィードバックを生成して詳細ページにリダイレクトすること" do
        entry_without_response = FactoryBot.create(:entry, user: @user, posted_on: Date.today + 5.days, response: nil)
        allow(AiFeedbackGenerator).to receive(:call).and_return('新しいフィードバック')
        
        post generate_feedback_entry_path(entry_without_response)
        
        expect(response).to redirect_to(entry_path(entry_without_response))
        expect(flash[:notice]).to eq('AIからのコメントを追加しました。')
      end

      it "エラーが発生した場合は詳細ページにリダイレクトすること" do
        entry_without_response = FactoryBot.create(:entry, user: @user, posted_on: Date.today + 6.days, response: nil)
        allow(AiFeedbackGenerator).to receive(:call).and_raise(StandardError, 'Error')
        
        post generate_feedback_entry_path(entry_without_response)
        
        expect(response).to redirect_to(entry_path(entry_without_response))
        expect(flash[:alert]).to eq('AIからのコメント生成に失敗しました。')
      end
    end
  end

  # 注: by_dateアクションはコントローラーに定義されていますが、
  # routes.rbにルートが設定されていないため、テストはスキップしています。
  # 必要に応じて、routes.rbに以下を追加してください:
  # get '/days/:date', to: 'entries#by_date', as: 'by_date'
end

