class EntriesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_entry, only: %i[show edit update destroy generate_feedback]

  def index
    @entries = Entry.all
  end

  def show; end

  def new
    @entry = current_user.entries.new(posted_on: Date.current) # デフォルト当日
  end

  def create
    @entry = current_user.entries.new(entry_params)
    if @entry.save
      redirect_to @entry, notice: "日記を投稿しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @entry.update(entry_params)
      redirect_to @entry, notice: "日記を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to entries_path, notice: "日記を削除しました。"
  end

  def generate_feedback
    if @entry.response.present?
      redirect_to @entry, notice: "AIからのコメントは既に生成済みです。"
      return
    end

    feedback = AiFeedbackGenerator.call(@entry)
    if @entry.update(response: feedback)
      redirect_to @entry, notice: "AIからのコメントを追加しました。"
    else
      redirect_to @entry, alert: "AIからのコメント保存に失敗しました。"
    end
  rescue StandardError => e
    Rails.logger.error("[EntriesController#generate_feedback] #{e.class}: #{e.message}")
    redirect_to @entry, alert: "AIからのコメント生成に失敗しました。"
  end

  # /days/:date → その日のエントリへ（1日1件前提で詳細へ直行）
  def by_date
    date = Date.parse(params[:date]) rescue nil
    return redirect_to entries_path, alert: "不正な日付です" unless date

    entry = current_user.entries.find_by(posted_on: date)
    if entry
      redirect_to entry
    else
      # 未投稿なら新規作成フォームへ（dateを初期値にしてあげる）
      redirect_to new_entry_path(entry: { posted_on: date })
    end
  end

  private

  def set_entry
    @entry = current_user.entries.find(params[:id])
  end

  def entry_params
    # tagsは後で実装予定なら一旦許可しない or :tag_ids => [] を付ける
    params.require(:entry).permit(:title, :content, :posted_on, :image)
  end
end
