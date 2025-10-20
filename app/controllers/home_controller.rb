class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # 最新の投稿5件を取得（Recent Entryセクション用）
    # Active Storage画像のN+1を防ぐためwith_attached_imageを追加
    @recent_entries = current_user.entries
                                   .with_attached_image
                                   .order(posted_on: :desc)
                                   .limit(5)
    
    # 最近登録した単語5件を取得
    # ビューでentries.firstを使用するためincludesを追加
    @recent_vocabularies = current_user.vocabularies
                                        .includes(entries: { image_attachment: :blob })
                                        .order(created_at: :desc)
                                        .limit(5)
    
    # 全投稿を取得（カレンダー表示用）
    @entries = current_user.entries.order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: @entries.select(:id, :title, :posted_on) }
    end
  end
end
