class UserService
  def self.create_user(user_params)
    new(user_params).create_user
  end

  def self.update_user(user:, user_params:)
    new(user_params, user).update_user
  end

  def self.get_user_statistics(user:)
    new({}, user).get_user_statistics
  end

  def self.get_learning_progress(user:)
    new({}, user).get_learning_progress
  end

  def self.get_motivation_message(user:)
    new({}, user).get_motivation_message
  end

  def initialize(user_params = {}, user = nil)
    @user_params = user_params
    @user = user
  end

  def create_user
    @user = User.new(@user_params)

    if @user.save
      {
        success: true,
        user: @user,
        message: "アカウントを作成しました。"
      }
    else
      {
        success: false,
        user: @user,
        errors: @user.errors.full_messages,
        message: "アカウントの作成に失敗しました。"
      }
    end
  end

  def update_user
    return { success: false, message: "ユーザーが見つかりません。" } unless @user

    if @user.update(@user_params)
      {
        success: true,
        user: @user,
        message: "プロフィールを更新しました。"
      }
    else
      {
        success: false,
        user: @user,
        errors: @user.errors.full_messages,
        message: "プロフィールの更新に失敗しました。"
      }
    end
  end

  def get_user_statistics
    return { success: false, message: "ユーザーが見つかりません。" } unless @user

    entries = @user.entries
    vocabularies = @user.vocabularies

    {
      success: true,
      statistics: {
        user: {
          nickname: @user.nickname,
          email: @user.email,
          created_at: @user.created_at,
          learning_level: calculate_learning_level(entries.count)
        },
        entries: {
          total_count: entries.count,
          this_month_count: entries.this_month.count,
          recent_count: entries.where(posted_on: 7.days.ago..).count,
          longest_streak: calculate_longest_streak(entries),
          current_streak: calculate_current_streak(entries)
        },
        vocabularies: {
          total_count: vocabularies.count,
          mastered_count: vocabularies.mastered.count,
          favorited_count: vocabularies.favorited.count,
          mastery_rate: vocabularies.count > 0 ? (vocabularies.mastered.count.to_f / vocabularies.count * 100).round(1) : 0,
          recent_additions: vocabularies.where(created_at: 7.days.ago..).count
        },
        achievements: get_achievements(entries, vocabularies)
      }
    }
  end

  def get_learning_progress
    return { success: false, message: "ユーザーが見つかりません。" } unless @user

    entries = @user.entries.order(:posted_on)
    vocabularies = @user.vocabularies

    {
      success: true,
      progress: {
        learning_level: calculate_learning_level(entries.count),
        streak_info: {
          current_streak: calculate_current_streak(entries),
          longest_streak: calculate_longest_streak(entries),
          streak_goal: 30 # 30日連続目標
        },
        vocabulary_progress: {
          total_words: vocabularies.count,
          mastered_words: vocabularies.mastered.count,
          mastery_percentage: vocabularies.count > 0 ? (vocabularies.mastered.count.to_f / vocabularies.count * 100).round(1) : 0,
          next_milestone: calculate_next_vocabulary_milestone(vocabularies.count)
        },
        writing_progress: {
          total_entries: entries.count,
          entries_this_month: entries.this_month.count,
          average_words_per_entry: calculate_average_words_per_entry(entries),
          next_milestone: calculate_next_writing_milestone(entries.count)
        }
      }
    }
  end

  def get_motivation_message
    return { success: false, message: "ユーザーが見つかりません。" } unless @user

    recent_entries = @user.entries.order(posted_on: :desc).limit(5)
    nickname = @user.nickname

    message = if recent_entries.empty?
      "Welcome, #{nickname}! Start your English learning journey today! 🚀"
    else
      generate_motivation_message(recent_entries, nickname)
    end

    {
      success: true,
      message: message,
      learning_level: calculate_learning_level(recent_entries.count)
    }
  end

  private

  def calculate_learning_level(entries_count)
    case entries_count
    when 0..4
      "初心者"
    when 5..19
      "学習中"
    when 20..49
      "中級者"
    when 50..99
      "上級者"
    else
      "エキスパート"
    end
  end

  def calculate_current_streak(entries)
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

  def calculate_longest_streak(entries)
    return 0 if entries.empty?

    dates = entries.pluck(:posted_on).sort.reverse
    longest_streak = 0
    current_streak = 0
    previous_date = nil

    dates.each do |date|
      if previous_date.nil? || date == previous_date - 1.day
        current_streak += 1
        longest_streak = [longest_streak, current_streak].max
      else
        current_streak = 1
      end
      previous_date = date
    end

    longest_streak
  end

  def calculate_average_words_per_entry(entries)
    return 0 if entries.empty?

    total_words = entries.sum { |entry| entry.content.split.length }
    (total_words.to_f / entries.count).round(1)
  end

  def calculate_next_vocabulary_milestone(current_count)
    milestones = [10, 25, 50, 100, 200, 500]
    milestones.find { |milestone| milestone > current_count } || "目標達成！"
  end

  def calculate_next_writing_milestone(current_count)
    milestones = [10, 25, 50, 100, 200, 365]
    milestones.find { |milestone| milestone > current_count } || "目標達成！"
  end

  def get_achievements(entries, vocabularies)
    achievements = []

    # エントリー関連の実績
    achievements << "初回投稿" if entries.count >= 1
    achievements << "10日間継続" if entries.count >= 10
    achievements << "30日間継続" if entries.count >= 30
    achievements << "100日間継続" if entries.count >= 100

    # 単語関連の実績
    achievements << "初回単語登録" if vocabularies.count >= 1
    achievements << "10単語マスター" if vocabularies.mastered.count >= 10
    achievements << "50単語マスター" if vocabularies.mastered.count >= 50
    achievements << "100単語マスター" if vocabularies.mastered.count >= 100

    # ストリーク関連の実績
    current_streak = calculate_current_streak(entries)
    achievements << "3日連続" if current_streak >= 3
    achievements << "7日連続" if current_streak >= 7
    achievements << "30日連続" if current_streak >= 30

    achievements
  end

  def generate_motivation_message(recent_entries, nickname)
    posted_days = recent_entries.map(&:posted_on).uniq.count
    last_entry_date = recent_entries.max_by(&:posted_on)&.posted_on
    today = Date.current
    days_since_last = (today - last_entry_date).to_i

    case
    when last_entry_date == today
      [
        "You finished today's entry! Great job, #{nickname}! 💪",
        "Nice work, #{nickname}! You've kept the streak going! ✨",
        "Well done, #{nickname}! Another day, another step forward! 🚀",
        "Fantastic consistency, #{nickname}! Keep that energy up! 🌟",
        "Awesome job, #{nickname}! Don't forget to review your words in My Dictionary! 📖"
      ].sample

    when last_entry_date == today - 1
      [
        "Let's keep the streak alive, #{nickname}! 🔥",
        "You're on a roll, #{nickname}! A little progress each day adds up to big results. 🌱",
        "Yesterday's effort was great, #{nickname}! Let's make today count too! 🌞",
        "Keep that momentum going, #{nickname}! Every day brings you closer to fluency. 📘"
      ].sample

    when posted_days >= 5
      [
        "You've built a fantastic habit, #{nickname}! 👏 Consistency is the key to success.",
        "Five days strong, #{nickname}! Your discipline is showing real progress! 💪",
        "That's an amazing routine you've built, #{nickname}! 🌿 Keep nurturing it!",
        "Writing regularly like this will take your English to the next level, #{nickname}! 🚀"
      ].sample

    when days_since_last.between?(2, 6)
      [
        "Even small things are worth writing about, #{nickname}! Keep journaling and boost your English skills. ✍️",
        "A few days off is no big deal, #{nickname}! Let's jump back in — practice makes perfect! 💫",
        "Every comeback starts with one new entry, #{nickname}! Let's write something small! 📝",
        "Time to pick up the pen again, #{nickname}! You've got this! 💪"
      ].sample

    else
      [
        "It's been a while since your last entry, #{nickname}. Let's start fresh today! 💪",
        "No worries if you took a break, #{nickname} — it's never too late to restart! 🔄",
        "Your journal's waiting for you, #{nickname}. Why not write something short today? 🌞",
        "Welcome back, #{nickname}! Every new start counts. ✨"
      ].sample
    end
  end
end
