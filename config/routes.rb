Rails.application.routes.draw do
  devise_for :users
  root "entries#index"
  resources :entries do
    post :generate_feedback, on: :member
    post :translate, on: :collection
    post :preview_feedback, on: :collection
  end

  # MyDictionary機能
  resources :vocabularies do
    collection do
      get :flashcard              # フラッシュカード復習ページ
      post :add_from_entry        # 日記から単語を追加（Ajax）
    end
    member do
      patch :toggle_mastered      # 習得済みトグル（Ajax）
      patch :toggle_favorited     # お気に入りトグル（Ajax）
    end
  end
end
