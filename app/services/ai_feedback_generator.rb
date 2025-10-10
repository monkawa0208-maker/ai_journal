class AiFeedbackGenerator
  def self.call(entry)
    new(entry).call
  end

  def initialize(entry)
    @entry = entry
  end

  def call
    [
      "こんにちは、AIジャーナルコーチです。",
      highlight_from_entry,
      encouragement
    ].compact.join("\n\n")
  end

  private

  attr_reader :entry

  def highlight_from_entry
    summary = sanitized_content
    headline = entry.title.presence || "今日の記録"

    if summary.empty?
      "#{headline}について、シンプルでも確かに前進していることが伝わってきます。直感的に浮かんでいる感情をもう1行書き添えると、未来のあなたが振り返りやすくなりますよ。"
    else
      "#{headline}では「#{summary}」と感じられたのですね。その気づきを大切にしながら、どうしたら同じ良い流れを続けられるか、あるいは調整できるかを一緒に考えてみましょう。"
    end
  end

  def encouragement
    metrics = []
    metrics << "投稿を続けること自体が大きな価値です。" if entry.posted_on.present?
    metrics << "次回は、今日の学びを一言ハイライトしてみるのもおすすめです。"
    metrics << "深呼吸をして、自分への小さな称賛も忘れずに。"
    metrics.join(" ")
  end

  def sanitized_content
    plain = entry.content.to_s.gsub(/\s+/, " ").strip
    return "" if plain.empty?

    plain = plain.slice(0, 80)
    plain << "…" if entry.content.to_s.size > 80
    plain
  end
end
