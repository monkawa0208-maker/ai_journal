require 'rails_helper'

# このテストはブラウザを開いて視覚的に確認するためのデモです
# 実行コマンド: HEADLESS=false bundle exec rspec spec/system/visual_demo_spec.rb
RSpec.describe "【デモ】ブラウザで動作確認", type: :system, js: true do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end

  describe "アプリケーションのビジュアルツアー" do
    it "主要な画面を順に表示する" do
      # 1. ホームページ
      visit root_path
      expect(page).to have_current_path(root_path)
      sleep 1  # ページロード待機
      save_screenshot('tmp/capybara/demo_1_home.png')
      sleep 2  # ゆっくり確認
      
      # 2. 日記一覧ページ
      click_link "日記一覧"
      expect(page).to have_current_path(entries_path)
      save_screenshot('tmp/capybara/demo_2_entries_list.png')
      sleep 2
      
      # 3. 新規日記作成ページ
      click_link "新規日記作成"
      expect(page).to have_content("新規日記作成")
      save_screenshot('tmp/capybara/demo_3_new_entry.png')
      sleep 2
      
      # 4. フォームに入力
      fill_in "entry_title", with: "Demo Entry"
      sleep 1
      fill_in "entry_content", with: "This is a demo entry for testing."
      sleep 1
      save_screenshot('tmp/capybara/demo_4_entry_filled.png')
      sleep 2
      
      # 5. 単語帳ページ
      visit vocabularies_path
      # ページが正しくロードされたことを確認
      expect(page).to have_current_path(vocabularies_path)
      save_screenshot('tmp/capybara/demo_5_vocabularies.png')
      sleep 2
      
      puts "\n"
      puts "=" * 60
      puts "✅ ビジュアルデモ完了！"
      puts "=" * 60
      puts "スクリーンショットが以下に保存されました："
      puts "  - tmp/capybara/demo_1_home.png"
      puts "  - tmp/capybara/demo_2_entries_list.png"
      puts "  - tmp/capybara/demo_3_new_entry.png"
      puts "  - tmp/capybara/demo_4_entry_filled.png"
      puts "  - tmp/capybara/demo_5_vocabularies.png"
      puts "=" * 60
      puts "\n"
    end
  end

  describe "日記の作成から編集までの完全なフロー" do
    it "日記を作成して編集できること" do
      # 既存の日記を作成
      entry = create(:entry, user: user, title: "編集前のタイトル", content: "編集前の内容")
      
      # 1. 日記詳細を表示
      visit entry_path(entry)
      expect(page).to have_current_path(entry_path(entry))
      save_screenshot('tmp/capybara/flow_1_show.png')
      sleep 2
      
      # 2. 編集ページに移動
      click_link "編集"
      expect(page).to have_current_path(edit_entry_path(entry))
      save_screenshot('tmp/capybara/flow_2_edit_form.png')
      sleep 2
      
      # 3. 内容を変更
      fill_in "entry_title", with: "編集後のタイトル"
      sleep 1
      save_screenshot('tmp/capybara/flow_3_edited.png')
      sleep 2
      
      puts "\n"
      puts "=" * 60
      puts "✅ 日記編集フロー完了！"
      puts "=" * 60
      puts "\n"
    end
  end

  describe "単語帳の機能確認" do
    let!(:vocab1) { create(:vocabulary, user: user, word: "happy", meaning: "幸せな", mastered: false) }
    let!(:vocab2) { create(:vocabulary, user: user, word: "grateful", meaning: "感謝している", mastered: true) }
    let!(:vocab3) { create(:vocabulary, user: user, word: "wonderful", meaning: "素晴らしい", favorited: true) }

    it "単語一覧とフィルタリングを確認できること" do
      # 1. 全単語を表示
      visit vocabularies_path
      expect(page).to have_content("happy")
      expect(page).to have_content("grateful")
      expect(page).to have_content("wonderful")
      save_screenshot('tmp/capybara/vocab_1_all.png')
      sleep 2
      
      # 2. 習得済みでフィルタ
      visit vocabularies_path(filter: 'mastered')
      expect(page).to have_content("grateful")
      save_screenshot('tmp/capybara/vocab_2_mastered.png')
      sleep 2
      
      # 3. 未習得でフィルタ
      visit vocabularies_path(filter: 'unmastered')
      expect(page).to have_content("happy")
      save_screenshot('tmp/capybara/vocab_3_unmastered.png')
      sleep 2
      
      # 4. お気に入りでフィルタ
      visit vocabularies_path(filter: 'favorited')
      expect(page).to have_content("wonderful")
      save_screenshot('tmp/capybara/vocab_4_favorited.png')
      sleep 2
      
      # 5. フラッシュカード
      visit flashcard_vocabularies_path
      expect(page).to have_content(/happy|grateful|wonderful/)
      save_screenshot('tmp/capybara/vocab_5_flashcard.png')
      sleep 2
      
      puts "\n"
      puts "=" * 60
      puts "✅ 単語帳機能の確認完了！"
      puts "=" * 60
      puts "\n"
    end
  end
end

