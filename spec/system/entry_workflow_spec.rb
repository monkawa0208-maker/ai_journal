require 'rails_helper'

RSpec.describe "日記作成ワークフロー", type: :system do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end

  describe "日記作成フロー" do
    it "日記を作成してAIフィードバックを取得できること", js: false do
      # AIサービスのモック
      allow(AiFeedbackGenerator).to receive(:call).and_return("Great work! Keep practicing!")
      
      visit new_entry_path
      
      expect(page).to have_content("新規日記作成")
      
      # タイトルと本文を入力
      fill_in "entry_title", with: "My First Entry"
      fill_in "entry_content", with: "Today I learned English. It was fun!"
      fill_in "entry_posted_on", with: Date.today - 200.days  # 他のテストと競合しない日付
      
      # 日記を保存
      click_button "保存する"
      
      # 詳細ページに遷移することを確認
      expect(page).to have_content("My First Entry")
      expect(page).to have_content("Today I learned English. It was fun!")
    end
  end

  describe "既存日記の編集" do
    let!(:entry) { create(:entry, user: user, title: "Original Title", content: "Original content", posted_on: Date.today - 201.days) }

    it "日記を編集できること", js: false do
      visit entry_path(entry)
      
      click_link "編集"
      expect(page).to have_current_path(edit_entry_path(entry))
      
      fill_in "entry_title", with: "Updated Title"
      click_button "保存する"
      
      # 詳細ページに遷移して更新が反映されることを確認
      expect(page).to have_content("Updated Title")
      entry.reload
      expect(entry.title).to eq("Updated Title")
    end
  end
end

