class VocabulariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary, only: [:show, :edit, :update, :destroy, :toggle_mastered, :toggle_favorited]

  # GET /vocabularies
  # 単語一覧ページ
  def index
    @vocabularies = current_user.vocabularies
                                 .includes(:entries)
                                 .recent

    # 検索パラメータがある場合
    if params[:search].present?
      @vocabularies = @vocabularies.search_by_word(params[:search])
    end

    # フィルタリング
    case params[:filter]
    when 'mastered'
      @vocabularies = @vocabularies.mastered
    when 'unmastered'
      @vocabularies = @vocabularies.unmastered
    when 'favorited'
      @vocabularies = @vocabularies.favorited
    end

    respond_to do |format|
      format.html do
        @vocabularies = @vocabularies.page(params[:page]).per(20)
      end
      format.json do
        # JSON形式の場合はページネーションなしで全件返す（検索用）
        render json: { vocabularies: @vocabularies.as_json(only: [:id, :word, :meaning, :mastered, :favorited]) }
      end
    end
  end

  # GET /vocabularies/flashcard
  # フラッシュカード復習ページ
  def flashcard
    @vocabularies = current_user.vocabularies.recent
    
    # フィルタリング（未習得のみなど）
    if params[:filter] == 'unmastered'
      @vocabularies = @vocabularies.unmastered
    end

    redirect_to vocabularies_path, alert: '復習する単語がありません' if @vocabularies.empty?
  end

  # GET /vocabularies/:id
  # 単語詳細ページ（必要に応じて実装）
  def show
  end

  # GET /vocabularies/new
  # 単語追加フォーム
  def new
    @vocabulary = current_user.vocabularies.build
    @entry_id = params[:entry_id]
  end

  # POST /vocabularies
  # 単語登録（通常フォーム）
  def create
    @vocabulary = current_user.vocabularies.build(vocabulary_params)

    if @vocabulary.save
      # 日記との関連付け
      if params[:entry_id].present?
        entry = current_user.entries.find(params[:entry_id])
        @vocabulary.entries << entry unless @vocabulary.entries.include?(entry)
      end

      redirect_to vocabularies_path, notice: '単語を登録しました'
    else
      render :new, status: :unprocessable_content
    end
  end

  # POST /vocabularies/add_from_entry (Ajax)
  # 日記ページから単語を追加
  def add_from_entry
    word = params[:word]&.strip&.downcase
    meaning = params[:meaning]&.strip
    entry_id = params[:entry_id]

    unless word.present? && meaning.present?
      render json: { error: '単語と意味が必要です' }, status: :unprocessable_content
      return
    end

    # 既存の単語を検索、なければ新規作成
    @vocabulary = current_user.vocabularies.find_or_initialize_by(word: word)
    
    is_new = @vocabulary.new_record?
    
    if @vocabulary.new_record?
      # 新規登録の場合
      @vocabulary.meaning = meaning
      unless @vocabulary.save
        render json: { error: @vocabulary.errors.full_messages.join(', ') }, status: :unprocessable_content
        return
      end
    else
      # 既存の単語の場合は意味を更新
      @vocabulary.meaning = meaning
      unless @vocabulary.save
        render json: { error: @vocabulary.errors.full_messages.join(', ') }, status: :unprocessable_content
        return
      end
    end

    # 日記との関連付け（entry_idがある場合のみ）
    if entry_id.present?
      entry = current_user.entries.find(entry_id)
      unless @vocabulary.entries.include?(entry)
        @vocabulary.entries << entry
      end
    end

    render json: { 
      success: true, 
      vocabulary: @vocabulary.as_json(include: :entries),
      is_new: is_new,
      message: is_new ? '単語を登録しました' : '単語を更新しました'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: '日記が見つかりません' }, status: :not_found
  end

  # GET /vocabularies/:id/edit
  # 単語編集フォーム
  def edit
  end

  # PATCH /vocabularies/:id
  # 単語更新
  def update
    if @vocabulary.update(vocabulary_params)
      redirect_to vocabularies_path, notice: '単語を更新しました'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /vocabularies/:id
  # 単語削除
  def destroy
    @vocabulary.destroy
    redirect_to vocabularies_path, notice: '単語を削除しました'
  end

  # PATCH /vocabularies/:id/toggle_mastered (Ajax)
  # 習得済みフラグをトグル
  def toggle_mastered
    @vocabulary.toggle_mastered!
    render json: { success: true, mastered: @vocabulary.mastered }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # PATCH /vocabularies/:id/toggle_favorited (Ajax)
  # お気に入りフラグをトグル
  def toggle_favorited
    @vocabulary.toggle_favorited!
    render json: { success: true, favorited: @vocabulary.favorited }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_vocabulary
    @vocabulary = current_user.vocabularies.find(params[:id])
  end

  def vocabulary_params
    params.require(:vocabulary).permit(:word, :meaning, :mastered, :favorited)
  end
end
