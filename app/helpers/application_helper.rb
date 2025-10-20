module ApplicationHelper
  # 日付のフォーマット
  def format_date(date)
    return "" unless date
    date.strftime("%Y年%m月%d日")
  end

  # 日時のフォーマット
  def format_datetime(datetime)
    return "" unless datetime
    datetime.strftime("%Y年%m月%d日 %H:%M")
  end

  # 文字数の制限
  def truncate_text(text, length = 100, omission = "...")
    return "" unless text
    truncate(text, length: length, omission: omission)
  end

  # 空の状態の表示
  def empty_state(icon:, title:, description:, action_text: nil, action_path: nil)
    content_tag :div, class: "empty-state" do
      concat content_tag(:div, icon, class: "empty-icon")
      concat content_tag(:h3, title, class: "empty-title")
      concat content_tag(:p, description, class: "empty-description")
      if action_text && action_path
        concat link_to(action_text, action_path, class: "button primary")
      end
    end
  end

  # ステータスバッジ
  def status_badge(status, type: :default)
    classes = case type
    when :success then "badge badge-success"
    when :warning then "badge badge-warning"
    when :danger then "badge badge-danger"
    when :info then "badge badge-info"
    else "badge badge-default"
    end
    
    content_tag :span, status, class: classes
  end

  # ページタイトルの設定
  def page_title(title = nil)
    if title
      content_for :title, "#{title} - AI Journal"
    else
      content_for?(:title) ? content_for(:title) : "AI Journal"
    end
  end

  # メタディスクリプションの設定
  def meta_description(description = nil)
    if description
      content_for :meta_description, description
    else
      content_for?(:meta_description) ? content_for(:meta_description) : "AI Journal - 英語学習日記アプリ"
    end
  end

  # アクティブなナビゲーション
  def active_nav_class(path)
    current_page?(path) ? "active" : ""
  end

  # フラッシュメッセージの表示
  def flash_messages
    return "" unless flash.any?
    
    content_tag :div, class: "flash-messages" do
      flash.each do |type, message|
        concat content_tag(:div, message, class: "flash-#{type}")
      end
    end
  end

  # ユーザーアバター
  def user_avatar(user, size: :medium)
    if user.avatar.attached?
      image_tag user.avatar, class: "user-avatar user-avatar-#{size}"
    else
      content_tag :div, user.nickname.first.upcase, class: "user-avatar user-avatar-#{size} user-avatar-placeholder"
    end
  end

  # 学習進捗の表示
  def learning_progress(entries_count)
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
end
