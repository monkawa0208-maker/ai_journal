require 'rails_helper'

RSpec.describe "シンプルなナビゲーションテスト", type: :system do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end

  describe "基本的なページ遷移" do
    it "ホームページにアクセスできること" do
      visit root_path
      
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("AI Journal")
    end

    it "日記一覧ページにアクセスできること" do
      visit entries_path
      
      expect(page).to have_current_path(entries_path)
      expect(page).to have_link("NEW POST")
    end

    it "単語帳ページにアクセスできること" do
      visit vocabularies_path
      
      expect(page).to have_current_path(vocabularies_path)
      expect(page).to have_content("My Dictionary")
    end
  end

  describe "日記の作成フロー" do
    it "新規日記作成ページにアクセスして内容を入力できること" do
      visit new_entry_path
      
      expect(page).to have_current_path(new_entry_path)
      expect(page).to have_content("新規投稿")
      
      # フォームに入力
      fill_in "entry_title", with: "My Test Entry"
      fill_in "entry_content", with: "This is a test content for my diary."
    end
  end

  describe "日記詳細の表示" do
    let!(:entry) { create(:entry, user: user, title: "テスト日記", content: "Test content") }

    it "作成した日記の詳細を表示できること" do
      visit entry_path(entry)
      
      expect(page).to have_current_path(entry_path(entry))
      expect(page).to have_content("テスト日記")
      expect(page).to have_content("Test content")
      
      # 編集ボタンと削除ボタンの確認
      expect(page).to have_link("編集")
      expect(page).to have_link("削除")
    end
  end

  describe "ナビゲーション" do
    it "ヘッダーのリンクから各ページに遷移できること" do
      visit root_path
      
      # 日記一覧へ
      click_link "日記一覧"
      expect(page).to have_current_path(entries_path)
      
      # 単語帳へ
      click_link "My Dictionary"
      expect(page).to have_current_path(vocabularies_path)
      
      # ホームに戻る
      click_link "AI Journal"
      expect(page).to have_current_path(root_path)
    end
  end
end

