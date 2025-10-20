class VocabularyService
  def self.add_from_entry(user:, word:, meaning:, entry_id: nil)
    new(user, word, meaning, entry_id).add_from_entry
  end

  def self.create_vocabulary(user:, vocabulary_params:)
    new(user, vocabulary_params[:word], vocabulary_params[:meaning]).create_vocabulary(vocabulary_params)
  end

  def self.update_vocabulary(vocabulary:, vocabulary_params:)
    new(vocabulary.user, vocabulary_params[:word], vocabulary_params[:meaning], nil, vocabulary).update_vocabulary(vocabulary_params)
  end

  def self.destroy_vocabulary(vocabulary:)
    new(vocabulary.user, vocabulary.word, vocabulary.meaning, nil, vocabulary).destroy_vocabulary
  end

  def self.toggle_mastered(vocabulary:)
    new(vocabulary.user, vocabulary.word, vocabulary.meaning, nil, vocabulary).toggle_mastered
  end

  def self.toggle_favorited(vocabulary:)
    new(vocabulary.user, vocabulary.word, vocabulary.meaning, nil, vocabulary).toggle_favorited
  end

  def self.search_vocabularies(user:, search_term:, filter: nil)
    new(user, search_term).search_vocabularies(search_term, filter)
  end

  def self.get_flashcard_vocabularies(user:, filter: nil)
    new(user).get_flashcard_vocabularies(filter)
  end

  def initialize(user, word = nil, meaning = nil, entry_id = nil, vocabulary = nil)
    @user = user
    @word = word
    @meaning = meaning
    @entry_id = entry_id
    @vocabulary = vocabulary
  end

  def add_from_entry
    begin
      # 既存の単語を検索、なければ新規作成
      vocabulary = @user.vocabularies.find_or_initialize_by(word: @word)
      is_new = vocabulary.new_record?
      
      # 意味を設定/更新
      vocabulary.meaning = @meaning
      
      unless vocabulary.save
        return {
          success: false,
          error: vocabulary.errors.full_messages.join(', ')
        }
      end

      # 日記との関連付け（entry_idがある場合のみ）
      if @entry_id.present?
        entry = @user.entries.find(@entry_id)
        vocabulary.entries << entry unless vocabulary.entries.include?(entry)
      end

      {
        success: true,
        vocabulary: vocabulary,
        is_new: is_new,
        message: is_new ? '単語を登録しました' : '単語を更新しました'
      }
    rescue ActiveRecord::RecordNotFound
      {
        success: false,
        error: '日記が見つかりません'
      }
    rescue StandardError => e
      Rails.logger.error("[VocabularyService] #{e.class}: #{e.message}")
      {
        success: false,
        error: '単語の登録に失敗しました'
      }
    end
  end

  def create_vocabulary(vocabulary_params)
    @vocabulary = @user.vocabularies.build(vocabulary_params)

    if @vocabulary.save
      {
        success: true,
        vocabulary: @vocabulary,
        message: '単語を登録しました'
      }
    else
      {
        success: false,
        vocabulary: @vocabulary,
        errors: @vocabulary.errors.full_messages,
        message: '単語の登録に失敗しました'
      }
    end
  end

  def update_vocabulary(vocabulary_params)
    return { success: false, message: "単語が見つかりません。" } unless @vocabulary

    if @vocabulary.update(vocabulary_params)
      {
        success: true,
        vocabulary: @vocabulary,
        message: '単語を更新しました'
      }
    else
      {
        success: false,
        vocabulary: @vocabulary,
        errors: @vocabulary.errors.full_messages,
        message: '単語の更新に失敗しました'
      }
    end
  end

  def destroy_vocabulary
    return { success: false, message: "単語が見つかりません。" } unless @vocabulary

    word = @vocabulary.word
    @vocabulary.destroy

    {
      success: true,
      message: "単語「#{word}」を削除しました。"
    }
  end

  def toggle_mastered
    return { success: false, message: "単語が見つかりません。" } unless @vocabulary

    begin
      @vocabulary.toggle_mastered!
      {
        success: true,
        vocabulary: @vocabulary,
        mastered: @vocabulary.mastered,
        message: @vocabulary.mastered ? "習得済みにしました" : "未習得にしました"
      }
    rescue StandardError => e
      Rails.logger.error("[VocabularyService#toggle_mastered] #{e.class}: #{e.message}")
      {
        success: false,
        error: e.message
      }
    end
  end

  def toggle_favorited
    return { success: false, message: "単語が見つかりません。" } unless @vocabulary

    begin
      @vocabulary.toggle_favorited!
      {
        success: true,
        vocabulary: @vocabulary,
        favorited: @vocabulary.favorited,
        message: @vocabulary.favorited ? "お気に入りにしました" : "お気に入りを解除しました"
      }
    rescue StandardError => e
      Rails.logger.error("[VocabularyService#toggle_favorited] #{e.class}: #{e.message}")
      {
        success: false,
        error: e.message
      }
    end
  end

  def search_vocabularies(search_term, filter = nil)
    vocabularies = @user.vocabularies.includes(:entries).recent

    # 検索フィルタリング
    if search_term.present?
      vocabularies = vocabularies.search_by_word(search_term)
    end

    # ステータスフィルタリング
    case filter
    when 'mastered'
      vocabularies = vocabularies.mastered
    when 'unmastered'
      vocabularies = vocabularies.unmastered
    when 'favorited'
      vocabularies = vocabularies.favorited
    end

    {
      success: true,
      vocabularies: vocabularies,
      count: vocabularies.count,
      message: "#{vocabularies.count}件の単語が見つかりました。"
    }
  end

  def get_flashcard_vocabularies(filter = nil)
    vocabularies = @user.vocabularies.recent

    # フィルタリング（未習得のみなど）
    if filter == 'unmastered'
      vocabularies = vocabularies.unmastered
    end

    if vocabularies.empty?
      {
        success: false,
        vocabularies: [],
        message: '復習する単語がありません'
      }
    else
      {
        success: true,
        vocabularies: vocabularies,
        count: vocabularies.count,
        message: "#{vocabularies.count}件の単語で復習できます。"
      }
    end
  end

  def get_statistics
    vocabularies = @user.vocabularies
    entries = @user.entries

    {
      success: true,
      statistics: {
        total_vocabularies: vocabularies.count,
        mastered_vocabularies: vocabularies.mastered.count,
        favorited_vocabularies: vocabularies.favorited.count,
        mastery_rate: vocabularies.count > 0 ? (vocabularies.mastered.count.to_f / vocabularies.count * 100).round(1) : 0,
        most_used_words: get_most_used_words(vocabularies),
        recent_additions: vocabularies.where(created_at: 7.days.ago..).count,
        words_by_entry: get_words_by_entry_count(entries)
      }
    }
  end

  private

  def get_most_used_words(vocabularies)
    vocabularies.joins(:entries)
               .group('vocabularies.id', 'vocabularies.word')
               .order('COUNT(entry_vocabularies.id) DESC')
               .limit(5)
               .pluck('vocabularies.word', 'COUNT(entry_vocabularies.id)')
               .map { |word, count| { word: word, usage_count: count } }
  end

  def get_words_by_entry_count(entries)
    entries.joins(:vocabularies)
           .group('entries.id', 'entries.title', 'entries.posted_on')
           .order('entries.posted_on DESC')
           .limit(10)
           .pluck('entries.title', 'entries.posted_on', 'COUNT(vocabularies.id)')
           .map { |title, date, count| { title: title, date: date, word_count: count } }
  end
end