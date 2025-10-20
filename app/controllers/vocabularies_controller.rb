class VocabulariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary, only: [:edit, :update, :destroy, :toggle_mastered, :toggle_favorited]

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


  # GET /vocabularies/new
  # 単語追加フォーム
  def new
    @vocabulary = current_user.vocabularies.build
    @entry_id = params[:entry_id]
  end

  # POST /vocabularies
  # 単語登録（通常フォーム）
  def create
    result = VocabularyService.create_vocabulary(
      user: current_user,
      vocabulary_params: vocabulary_params
    )

    if result[:success]
      # 日記との関連付け
      if params[:entry_id].present?
        entry_result = EntryService.new(current_user, {}, result[:vocabulary]).add_vocabulary(
          word: result[:vocabulary].word,
          meaning: result[:vocabulary].meaning
        )
      end

      redirect_with_message(vocabularies_path, result[:message])
    else
      @vocabulary = result[:vocabulary]
      handle_validation_errors(@vocabulary, :new) do
        set_flash_message(:alert, result[:message])
      end
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

    result = VocabularyService.add_from_entry(
      user: current_user,
      word: word,
      meaning: meaning,
      entry_id: entry_id
    )

    if result[:success]
      render json: { 
        success: true, 
        vocabulary: result[:vocabulary].as_json(include: :entries),
        is_new: result[:is_new],
        message: result[:message]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_content
    end
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
    result = VocabularyService.toggle_mastered(vocabulary: @vocabulary)
    
    if result[:success]
      render json: { 
        success: true, 
        mastered: result[:mastered],
        message: result[:message]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_content
    end
  end

  # PATCH /vocabularies/:id/toggle_favorited (Ajax)
  # お気に入りフラグをトグル
  def toggle_favorited
    result = VocabularyService.toggle_favorited(vocabulary: @vocabulary)
    
    if result[:success]
      render json: { 
        success: true, 
        favorited: result[:favorited],
        message: result[:message]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_content
    end
  end

  private

  def set_vocabulary
    @vocabulary = current_user.vocabularies.find(params[:id])
  end

  def vocabulary_params
    params.require(:vocabulary).permit(:word, :meaning, :mastered, :favorited)
  end
end
