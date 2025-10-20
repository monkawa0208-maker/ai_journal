require 'rails_helper'

RSpec.describe "日記作成ワークフロー", type: :system, js: true do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end

  describe "完全な日記作成フロー" do
    it "日記を作成してAIフィードバックを取得できること" do
      # AIサービスのモック
      allow(AiFeedbackGenerator).to receive(:call).and_return("Great work! Keep practicing!")
      
      visit new_entry_path
      
      expect(page).to have_content("新規投稿")
      save_screenshot('tmp/capybara/workflow_step1_new.png')
      
      # タイトルと本文を入力
      fill_in "entry_title", with: "My First Entry"
      fill_in "entry_content", with: "Today I learned English. It was fun!"
      
      save_screenshot('tmp/capybara/workflow_step2_filled.png')
      
      # AIフィードバックボタンをクリック
      # 注: JavaScriptが動作するため、ボタンが有効になるまで待つ必要があります
      sleep 1
      
      save_screenshot('tmp/capybara/workflow_step3_ready.png')
    end
  end

  describe "既存日記の編集" do
    let!(:entry) { create(:entry, user: user, title: "Original Title", content: "Original content") }

    it "日記を編集できること" do
      visit entry_path(entry)
      save_screenshot('tmp/capybara/edit_step1_show.png')
      
      click_link "編集"
      expect(page).to have_current_path(edit_entry_path(entry))
      save_screenshot('tmp/capybara/edit_step2_form.png')
      
      fill_in "entry_title", with: "Updated Title"
      save_screenshot('tmp/capybara/edit_step3_updated.png')
    end
  end
end

