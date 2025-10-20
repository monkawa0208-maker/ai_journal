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
    result = EntryService.create_entry(
      user: current_user,
      entry_params: entry_params
    )

    if result[:success]
      redirect_with_message(result[:entry], result[:message])
    else
      @entry = result[:entry]
      handle_validation_errors(@entry, :new) do
        set_flash_message(:alert, result[:message])
      end
    end
  end

  def edit; end

  def update
    result = EntryService.update_entry(
      entry: @entry,
      entry_params: entry_params
    )

    if result[:success]
      redirect_with_message(result[:entry], result[:message])
    else
      @entry = result[:entry]
      handle_validation_errors(@entry, :edit) do
        set_flash_message(:alert, result[:message])
      end
    end
  end

  def destroy
    result = EntryService.destroy_entry(entry: @entry)
    redirect_with_message(entries_path, result[:message])
  end

  def translate
    japanese_text = params[:text]
    
    if japanese_text.blank?
      return render json: { error: "翻訳するテキストが入力されていません。" }, status: :unprocessable_content
    end

    result = handle_ai_service_call(AiTranslator, japanese_text)
    render_json_response(
      success: result[:success],
      data: result[:success] ? { translation: result[:data] } : nil,
      error: result[:error]
    )
  end

  def preview_feedback
    title = params[:title]
    content = params[:content]
    
    if title.blank? || content.blank?
      return render json: { error: "タイトルと本文を入力してください。" }, status: :unprocessable_content
    end

    # 一時的なエントリーオブジェクトを作成（保存しない）
    temp_entry = current_user.entries.build(
      title: title,
      content: content,
      posted_on: Date.current
    )

    result = handle_ai_service_call(AiFeedbackGenerator, temp_entry)
    render_json_response(
      success: result[:success],
      data: result[:success] ? { response: result[:data] } : nil,
      error: result[:error]
    )
  end

  def generate_feedback
    if request.format.json?
      if @entry.response.present?
        return render json: { response: @entry.response }, status: :ok
      end

      result = handle_ai_service_call(AiFeedbackGenerator, @entry)
      if result[:success] && @entry.update(response: result[:data])
        render json: { response: @entry.response }, status: :ok
      else
        error_message = result[:error] ? "AIからのコメント生成に失敗しました。" : "AIからのコメントが保存できませんでした。"
        render json: { error: error_message }, status: :internal_server_error
      end
    else
      if @entry.response.present?
        redirect_with_message(@entry, "AIからのコメントは既に生成済みです。")
        return
      end

      result = handle_ai_service_call(AiFeedbackGenerator, @entry)
      if result[:success] && @entry.update(response: result[:data])
        redirect_with_message(@entry, "AIからのコメントを追加しました。")
      else
        error_message = "AIからのコメント生成に失敗しました。"
        redirect_with_message(@entry, error_message, type: :alert)
      end
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
