module EntriesHelper
  def motivation_message(recent_entries, user)
    nickname = user.nickname

    return "Welcome, #{nickname}!　右上の”新規日記作成”ボタンから日記を作成してください！<br>Start your English learning journey today! 🚀".html_safe if recent_entries.empty?

    posted_days = recent_entries.map(&:posted_on).uniq.count
    last_entry_date = recent_entries.max_by(&:posted_on)&.posted_on
    today = Date.current
    days_since_last = (today - last_entry_date).to_i

    case
    when last_entry_date == today
      "#{[
        "You finished today’s entry! Great job, #{nickname}! 💪",
        "Nice work, #{nickname}! You’ve kept the streak going! ✨",
        "Well done, #{nickname}! Another day, another step forward! 🚀",
        "Fantastic consistency, #{nickname}! Keep that energy up! 🌟",
        "Awesome job, #{nickname}! Don’t forget to review your words in My Dictionary! 📖"
      ].sample}<br>日記の作成お疲れ様でした！💪　単語の復習はMy Dictionaryを活用しましょう！📖".html_safe

    when last_entry_date == today - 1
      [
        "Let’s keep the streak alive, #{nickname}! 🔥",
        "You’re on a roll, #{nickname}! A little progress each day adds up to big results. 🌱",
        "Yesterday’s effort was great, #{nickname}! Let’s make today count too! 🌞",
        "Keep that momentum going, #{nickname}! Every day brings you closer to fluency. 📘"
      ].sample

    when posted_days >= 5
      [
        "You’ve built a fantastic habit, #{nickname}! 👏 Consistency is the key to success.",
        "Five days strong, #{nickname}! Your discipline is showing real progress! 💪",
        "That’s an amazing routine you’ve built, #{nickname}! 🌿 Keep nurturing it!",
        "Writing regularly like this will take your English to the next level, #{nickname}! 🚀"
      ].sample

    when days_since_last.between?(2, 6)
      [
        "Even small things are worth writing about, #{nickname}! Keep journaling and boost your English skills. ✍️",
        "A few days off is no big deal, #{nickname}! Let’s jump back in — practice makes perfect! 💫",
        "Every comeback starts with one new entry, #{nickname}! Let’s write something small! 📝",
        "Time to pick up the pen again, #{nickname}! You’ve got this! 💪"
      ].sample

    else
      [
        "It’s been a while since your last entry, #{nickname}. Let’s start fresh today! 💪",
        "No worries if you took a break, #{nickname} — it’s never too late to restart! 🔄",
        "Your journal’s waiting for you, #{nickname}. Why not write something short today? 🌞",
        "Welcome back, #{nickname}! Every new start counts. ✨"
      ].sample
    end
  end
end

