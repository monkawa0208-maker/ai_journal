class EntryVocabulary < ApplicationRecord
  belongs_to :entry
  belongs_to :vocabulary

  validates :entry_id, uniqueness: { scope: :vocabulary_id }
end
