class Vocabulary < ApplicationRecord
  belongs_to :user
  has_many :entry_vocabularies, dependent: :destroy
  has_many :entries, through: :entry_vocabularies

  validates :word, presence: true, 
                   length: { maximum: 255 },
                   uniqueness: { scope: :user_id, message: 'は既に登録されています' }
  validates :meaning, presence: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:word) }
  scope :mastered, -> { where(mastered: true) }
  scope :unmastered, -> { where(mastered: false) }
  scope :favorited, -> { where(favorited: true) }
  scope :search_by_word, ->(keyword) { where('word LIKE ?', "%#{keyword}%") if keyword.present? }

  # インスタンスメソッド
  def toggle_mastered!
    update!(mastered: !mastered)
  end

  def toggle_favorited!
    update!(favorited: !favorited)
  end
end
