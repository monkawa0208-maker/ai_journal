class Entry < ApplicationRecord

  belongs_to :user
  has_one_attached :image   # Active Storage：画像添付
  has_many :entry_vocabularies, dependent: :destroy
  has_many :vocabularies, through: :entry_vocabularies

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :posted_on, presence: true
  validate :unique_posted_on_per_user  # 1日1件ルール
  validate :acceptable_image  # 画像サイズとフォーマットの検証

  validates :response, length: { maximum: 10_000 }, allow_nil: true

  scope :recent, -> { order(posted_on: :desc) }
  scope :this_month, -> { where(posted_on: Date.current.all_month) }

  private

  def unique_posted_on_per_user
    return if posted_on.nil? || user.nil?
    
    existing_entry = user.entries.where(posted_on: posted_on).where.not(id: id).first
    if existing_entry
      errors.add(:base, 'すでにこの日の日記は作成済みです')
    end
  end

  # 画像のバリデーション（メモリ使用量を抑えるため）
  def acceptable_image
    return unless image.attached?

    # ファイルサイズの制限（10MB以下）
    if image.byte_size > 10.megabytes
      errors.add(:image, '画像ファイルは10MB以下にしてください')
    end

    # 許可する画像フォーマット
    acceptable_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    unless acceptable_types.include?(image.content_type)
      errors.add(:image, '画像はJPEG, PNG, GIF, WebP形式でアップロードしてください')
    end
  end

end

