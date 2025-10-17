class Entry < ApplicationRecord

  belongs_to :user
  has_one_attached :image   # Active Storage：画像添付
  has_many :entry_vocabularies, dependent: :destroy
  has_many :vocabularies, through: :entry_vocabularies

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :posted_on, presence: true, uniqueness: { scope: :user_id }  # 1日1件ルール

  validates :response, length: { maximum: 10_000 }, allow_nil: true

  scope :recent, -> { order(posted_on: :desc) }
  scope :this_month, -> { where(posted_on: Date.current.all_month) }

end

