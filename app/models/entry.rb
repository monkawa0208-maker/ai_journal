class Entry < ApplicationRecord

  belongs_to :user
  has_one_attached :image   # Active Storage：画像添付

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :posted_on, presence: true, uniqueness: { scope: :user_id }  # 1日1件ルール

  validates :response, length: { maximum: 10_000 }, allow_nil: true

  validates :image,
            content_type: %w[image/png image/jpg image/jpeg],
            size: { less_than: 5.megabytes, message: "5MB未満の画像をアップロードしてください" },
            allow_nil: true

  scope :recent, -> { order(posted_on: :desc) }
  scope :this_month, -> { where(posted_on: Date.current.all_month) }

end

