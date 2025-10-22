class EntryService
  def self.create_entry(user:, entry_params:)
    new(user, entry_params).create_entry
  end

  def self.update_entry(entry:, entry_params:)
    new(entry.user, entry_params, entry).update_entry
  end

  def self.destroy_entry(entry:)
    new(entry.user, {}, entry).destroy_entry
  end

  def self.find_by_date(user:, date:)
    new(user, {}).find_by_date(date)
  end

  def self.search_entries(user:, search_term:)
    new(user, {}).search_entries(search_term)
  end

  def initialize(user, entry_params = {}, entry = nil)
    @user = user
    @entry_params = entry_params
    @entry = entry
  end

  def create_entry
    @entry = @user.entries.build(@entry_params)
    
    # タイトルが空でcontentがある場合、AIでタイトルを自動生成
    if @entry.title.blank? && @entry.content.present?
      begin
        generated_title = AiTitleGenerator.call(@entry.content)
        @entry.title = generated_title if generated_title.present?
      rescue => e
        Rails.logger.error("タイトル自動生成エラー: #{e.message}")
        # エラーが発生してもデフォルトタイトルを設定
        @entry.title = "日記 #{Date.current.strftime('%Y-%m-%d')}"
      end
    end
    
    if @entry.save
      {
        success: true,
        entry: @entry,
        message: "日記を投稿しました。"
      }
    else
      {
        success: false,
        entry: @entry,
        errors: @entry.errors.full_messages,
        message: "日記の投稿に失敗しました。"
      }
    end
  end

  def update_entry
    return { success: false, message: "エントリーが見つかりません。" } unless @entry

    # タイトルが空でcontentがある場合、AIでタイトルを自動生成
    params_to_update = @entry_params.dup
    if params_to_update[:title].blank? && (params_to_update[:content].present? || @entry.content.present?)
      begin
        content_for_title = params_to_update[:content].presence || @entry.content
        generated_title = AiTitleGenerator.call(content_for_title)
        params_to_update[:title] = generated_title if generated_title.present?
      rescue => e
        Rails.logger.error("タイトル自動生成エラー: #{e.message}")
        # エラーが発生してもデフォルトタイトルを設定
        params_to_update[:title] = "日記 #{Date.current.strftime('%Y-%m-%d')}"
      end
    end

    if @entry.update(params_to_update)
      {
        success: true,
        entry: @entry,
        message: "日記を更新しました。"
      }
    else
      {
        success: false,
        entry: @entry,
        errors: @entry.errors.full_messages,
        message: "日記の更新に失敗しました。"
      }
    end
  end

  def destroy_entry
    return { success: false, message: "エントリーが見つかりません。" } unless @entry

    @entry.destroy

    {
      success: true,
      message: "日記を削除しました。"
    }
  end

  def find_by_date(date)
    entry = @user.entries.find_by(posted_on: date)
    
    if entry
      {
        success: true,
        entry: entry,
        message: "指定日の日記が見つかりました。"
      }
    else
      {
        success: false,
        entry: nil,
        message: "指定日の日記は見つかりませんでした。"
      }
    end
  end

  def search_entries(search_term)
    return { success: false, entries: [], message: "検索語が指定されていません。" } if search_term.blank?

    search_pattern = "%#{search_term}%"
    entries = @user.entries.where("title LIKE ? OR content LIKE ?", search_pattern, search_pattern)
                   .order(posted_on: :desc)

    {
      success: true,
      entries: entries,
      count: entries.count,
      message: "#{entries.count}件の日記が見つかりました。"
    }
  end

  def generate_ai_feedback
    return { success: false, message: "エントリーが見つかりません。" } unless @entry
    return { success: false, message: "AIからのコメントは既に生成済みです。" } if @entry.response.present?

    result = AiFeedbackGenerator.call(@entry)
    
    if @entry.update(response: result)
      {
        success: true,
        entry: @entry,
        feedback: result,
        message: "AIからのコメントを追加しました。"
      }
    else
      {
        success: false,
        entry: @entry,
        errors: @entry.errors.full_messages,
        message: "AIからのコメント保存に失敗しました。"
      }
    end
  end

  def add_vocabulary(word:, meaning:)
    return { success: false, message: "エントリーが見つかりません。" } unless @entry

    result = VocabularyService.add_from_entry(
      user: @user,
      word: word,
      meaning: meaning,
      entry_id: @entry.id
    )

    if result[:success]
      # エントリーと単語の関連付けを更新
      @entry.reload
      {
        success: true,
        vocabulary: result[:vocabulary],
        entry: @entry,
        message: result[:message]
      }
    else
      {
        success: false,
        message: result[:error]
      }
    end
  end

  def get_statistics
    return { success: false, message: "ユーザーが見つかりません。" } unless @user

    entries = @user.entries
    vocabularies = @user.vocabularies

    {
      success: true,
      statistics: {
        total_entries: entries.count,
        total_vocabularies: vocabularies.count,
        mastered_vocabularies: vocabularies.mastered.count,
        recent_entries_count: entries.where(posted_on: 7.days.ago..).count,
        learning_streak: calculate_learning_streak(entries),
        most_used_words: get_most_used_words(vocabularies)
      }
    }
  end

  private

  def calculate_learning_streak(entries)
    return 0 if entries.empty?

    dates = entries.pluck(:posted_on).sort.reverse
    streak = 0
    current_date = Date.current

    dates.each do |date|
      if date == current_date || date == current_date - streak.days
        streak += 1
        current_date = date - 1.day
      else
        break
      end
    end

    streak
  end

  def get_most_used_words(vocabularies)
    vocabularies.joins(:entries)
               .group('vocabularies.id', 'vocabularies.word')
               .order('COUNT(entry_vocabularies.id) DESC')
               .limit(5)
               .pluck('vocabularies.word', 'COUNT(entry_vocabularies.id)')
               .map { |word, count| { word: word, usage_count: count } }
  end
end
