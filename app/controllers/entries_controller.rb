class EntriesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_entry, only: %i[show edit update destroy generate_feedback]

  def index
    # 全投稿を取得
    @entries = current_user.entries.order(posted_on: :desc)
    
    # 検索パラメータがある場合
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @entries = @entries.where("title LIKE ? OR content LIKE ?", search_term, search_term)
    end
    
    # Recent Entryセクション用（検索結果も反映）
    @recent_entries = @entries
    
    respond_to do |format|
      format.html
      format.json { render json: @entries.select(:id, :title, :posted_on) }
    end
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
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @entry.update(entry_params)
      redirect_to @entry, notice: "日記を更新しました。"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @entry.destroy
    redirect_to entries_path, notice: "日記を削除しました。"
  end

  def translate
    japanese_text = params[:text]
    
    if japanese_text.blank?
      return render json: { error: "翻訳するテキストが入力されていません。" }, status: :unprocessable_content
    end

    translated_text = AiTranslator.call(japanese_text)
    render json: { translation: translated_text }, status: :ok
  rescue AiTranslator::TranslationError => e
    Rails.logger.error("[EntriesController#translate] #{e.class}: #{e.message}")
    render json: { error: e.message }, status: :internal_server_error
  rescue StandardError => e
    Rails.logger.error("[EntriesController#translate] #{e.class}: #{e.message}")
    render json: { error: "翻訳処理中にエラーが発生しました。" }, status: :internal_server_error
  end

  def preview_feedback
    content = params[:content]
    
    if content.blank?
      return render json: { error: "本文（英語）を入力してください。" }, status: :unprocessable_content
    end

    # タイトルがない場合はデフォルト値を使用
    title = params[:title].presence || "Untitled"

    # 一時的なエントリーオブジェクトを作成（保存しない）
    temp_entry = current_user.entries.build(
      title: title,
      content: content,
      posted_on: Date.current
    )

    feedback = AiFeedbackGenerator.call(temp_entry)
    render json: { response: feedback }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[EntriesController#preview_feedback] #{e.class}: #{e.message}")
    render json: { error: "フィードバック生成に失敗しました。" }, status: :internal_server_error
  end

  def generate_feedback
    if request.format.json?
      if @entry.response.present?
        return render json: { response: @entry.response }, status: :ok
      end

      feedback = AiFeedbackGenerator.call(@entry)
      if @entry.update(response: feedback)
        render json: { response: @entry.response }, status: :ok
      else
        render json: { error: "AIからのコメントが保存できませんでした。" }, status: :unprocessable_content
      end
    else
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
    end
  rescue StandardError => e
    Rails.logger.error("[EntriesController#generate_feedback] #{e.class}: #{e.message}")
    if request.format.json?
      render json: { error: "AIからのコメント生成に失敗しました。" }, status: :internal_server_error
    else
      redirect_to @entry, alert: "AIからのコメント生成に失敗しました。"
    end
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
    @entry = current_user.entries.includes(:vocabularies).find(params[:id])
  end

  def entry_params
    # tagsは後で実装予定なら一旦許可しない or :tag_ids => [] を付ける
    params.require(:entry).permit(:title, :content, :content_ja, :ai_translate, :response, :posted_on, :image)
  end
end
