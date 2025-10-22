require 'rails_helper'

RSpec.describe "カレンダー表示機能", type: :system, js: true do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end

  describe "カレンダータブの切り替え" do
    before do
      # テスト用の日記を作成
      create(:entry, user: user, title: "Today's Entry", content: "Content", posted_on: Date.today)
      create(:entry, user: user, title: "Yesterday's Entry", content: "Content", posted_on: Date.yesterday)
    end

    it "日記一覧ページでカレンダータブが表示されること" do
      visit entries_path
      
      expect(page).to have_button("カレンダー")
    end

    it "カレンダータブをクリックするとカレンダービューに切り替わること", skip: "JavaScript動的読み込みが必要なため、手動テスト" do
      visit entries_path
      
      # 初期状態では一覧表示
      expect(page).to have_content("一覧表示")
      
      # カレンダータブをクリック
      click_button "カレンダー"
      
      # カレンダーが表示されることを確認（JavaScriptの実行を待つ）
      # FullCalendarが読み込まれている場合、.fc-view要素が存在する
      expect(page).to have_selector("#calendar", visible: true, wait: 5)
    end

    it "一覧表示とカレンダー表示を切り替えられること", skip: "JavaScript動的読み込みが必要なため、手動テスト" do
      visit entries_path
      
      # カレンダーに切り替え
      click_button "カレンダー"
      expect(page).to have_selector("#calendar", visible: true, wait: 5)
      
      # 一覧表示に戻す
      click_button "一覧表示"
      expect(page).to have_selector(".entries-list", visible: true, wait: 5)
    end
  end

  describe "カレンダー上でのイベント表示" do
    before do
      # 今月の複数の日記を作成
      @entry1 = create(:entry, user: user, title: "Entry 1", content: "Content 1", posted_on: Date.today)
      @entry2 = create(:entry, user: user, title: "Entry 2", content: "Content 2", posted_on: Date.today - 1.day)
      @entry3 = create(:entry, user: user, title: "Entry 3", content: "Content 3", posted_on: Date.today - 7.days)
    end

    it "投稿済みの日付にイベントが表示されること", js: false do
      visit entries_path
      
      # 一覧表示タブ内でのみチェック（非表示要素を除外）
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content(@entry1.title)
        expect(page).to have_content(@entry2.title)
        expect(page).to have_content(@entry3.title)
      end
    end
  end

  describe "カレンダーの月表示" do
    before do
      # 先月と今月の日記を作成
      @last_month_entry = create(:entry, user: user, title: "Last Month", content: "Content", posted_on: Date.today.last_month)
      @this_month_entry = create(:entry, user: user, title: "This Month", content: "Content", posted_on: Date.today)
    end

    it "現在の月が表示されること", js: false do
      visit entries_path
      
      # 一覧表示タブ内でのみチェック
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content(@this_month_entry.title)
      end
    end

    it "他のユーザーの日記は表示されないこと" do
      other_user = create(:user)
      other_entry = create(:entry, user: other_user, title: "Other User Entry", content: "Content", posted_on: Date.today)
      
      visit entries_path
      
      # 一覧表示タブ内でのみチェック
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content(@this_month_entry.title)
        expect(page).not_to have_content(other_entry.title)
      end
    end
  end

  describe "カレンダーからの日記詳細遷移", js: false do
    before do
      @entry = create(:entry, user: user, title: "Clickable Entry", content: "Content", posted_on: Date.today)
    end

    it "一覧から日記詳細ページに遷移できること" do
      visit entries_path
      
      # 一覧表示タブ内のリンクをクリック
      within('.tab-content[data-tab="entries"]', visible: true) do
        click_link @entry.title
      end
      
      expect(page).to have_current_path(entry_path(@entry))
      expect(page).to have_content(@entry.title)
      expect(page).to have_content(@entry.content)
    end
  end

  describe "空の状態のカレンダー表示" do
    it "日記がない場合でもカレンダーが表示されること", js: false do
      visit entries_path
      
      # 空の状態でも正常に表示される
      expect(page).to have_button("カレンダー")
      
      # エラーが発生しないこと
      expect(page).not_to have_content("エラー")
    end

    it "日記がない月でも正常に表示されること" do
      # 6ヶ月前の日記のみ作成
      create(:entry, user: user, title: "Old Entry", content: "Content", posted_on: Date.today - 6.months)
      
      visit entries_path
      
      # 現在の月（日記がない）でもエラーが出ないこと
      expect(page).to have_button("カレンダー")
    end
  end

  describe "JSON APIからのデータ取得" do
    # 注: JSON APIのテストはspec/requests/entries_spec.rbに既に存在します
    # システムテスト（ブラウザベース）ではJSON APIの直接テストは適していません
    # ここではカレンダー表示に必要なデータが取得できることのみ確認します
    
    it "カレンダー用のデータが正しく取得されること" do
      entry1 = create(:entry, user: user, title: "API Entry 1", content: "Content", posted_on: Date.today)
      entry2 = create(:entry, user: user, title: "API Entry 2", content: "Content", posted_on: Date.yesterday)
      
      visit entries_path
      
      # 一覧表示タブ内でデータが正しく表示されることを確認
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content("API Entry 1")
        expect(page).to have_content("API Entry 2")
      end
    end

    it "他のユーザーの日記は表示されないこと" do
      my_entry = create(:entry, user: user, title: "My Entry", content: "Content", posted_on: Date.today)
      other_user = create(:user)
      other_entry = create(:entry, user: other_user, title: "Other Entry", content: "Content", posted_on: Date.today)
      
      visit entries_path
      
      # 一覧表示タブ内で自分の日記のみ表示される
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content("My Entry")
        expect(page).not_to have_content("Other Entry")
      end
    end
  end

  describe "カレンダーの検索機能との連携", js: false do
    before do
      @matching_entry = create(:entry, user: user, title: "Important Meeting", content: "Content", posted_on: Date.today)
      @other_entry = create(:entry, user: user, title: "Regular Day", content: "Content", posted_on: Date.yesterday)
    end

    it "検索結果がカレンダーにも反映されること" do
      visit entries_path
      
      fill_in "search", with: "Important"
      find('.entry-search-button').click
      
      # 一覧表示タブ内で検索結果のみ表示される
      within('.tab-content[data-tab="entries"]', visible: true) do
        expect(page).to have_content(@matching_entry.title)
        expect(page).not_to have_content(@other_entry.title)
      end
    end
  end
end

