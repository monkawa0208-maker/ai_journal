class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # 最新の投稿5件を取得（Recent Entryセクション用）
    @recent_entries = current_user.entries.order(posted_on: :desc).limit(5)
    
    # 全投稿を取得（カレンダー表示用）
    @entries = current_user.entries.order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: @entries.select(:id, :title, :posted_on) }
    end
  end
end
