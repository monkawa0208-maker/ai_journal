require 'rails_helper'

RSpec.describe "Home", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトすること" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user
      end

      it "正常にアクセスできること" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "最新のエントリーを表示すること" do
        entry1 = create(:entry, user: user, posted_on: Date.today)
        entry2 = create(:entry, user: user, posted_on: Date.yesterday)
        
        get root_path
        expect(response.body).to include(entry1.title)
        expect(response.body).to include(entry2.title)
      end

      it "最新の単語を表示すること" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "最大5件の最新エントリーを取得すること" do
        10.times do |i|
          create(:entry, user: user, posted_on: Date.today - i.days)
        end
        
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "最大5件の最新単語を取得すること" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "全エントリーを取得すること" do
        3.times do |i|
          create(:entry, user: user, posted_on: Date.today - i.days)
        end
        
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "他のユーザーのエントリーは表示しないこと" do
        other_user = create(:user)
        other_entry = create(:entry, user: other_user)
        
        get root_path
        expect(response.body).not_to include(other_entry.title)
      end

      it "他のユーザーの単語は表示しないこと" do
        other_user = create(:user)
        other_vocabulary = create(:vocabulary, user: other_user, word: 'test')
        
        get root_path
        expect(response.body).not_to include(other_vocabulary.word)
      end

      context "JSON形式でのリクエスト" do
        it "エントリー一覧をJSON形式で返すこと" do
          entry1 = create(:entry, user: user, posted_on: Date.today)
          entry2 = create(:entry, user: user, posted_on: Date.yesterday)
          
          get root_path, as: :json
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include('application/json')
          
          json_response = JSON.parse(response.body)
          expect(json_response).to be_an(Array)
          expect(json_response.count).to eq(2)
          expect(json_response.first).to have_key('id')
          expect(json_response.first).to have_key('title')
          expect(json_response.first).to have_key('posted_on')
        end

        it "必要なフィールドのみを返すこと" do
          create(:entry, user: user)
          
          get root_path, as: :json
          json_response = JSON.parse(response.body)
          
          expect(json_response.first.keys).to contain_exactly('id', 'title', 'posted_on')
          expect(json_response.first).not_to have_key('content')
          expect(json_response.first).not_to have_key('response')
        end
      end
    end
  end

  describe "エントリーが存在しない場合" do
    before do
      sign_in user
    end

    it "エラーなく表示できること" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end

