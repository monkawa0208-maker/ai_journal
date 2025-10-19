class CreateEntryVocabularies < ActiveRecord::Migration[7.1]
  def change
    create_table :entry_vocabularies do |t|
      t.references :entry, null: false, foreign_key: true, comment: '日記ID'
      t.references :vocabulary, null: false, foreign_key: true, comment: '単語ID'

      t.timestamps
    end

    add_index :entry_vocabularies, [:entry_id, :vocabulary_id], unique: true, name: 'index_entry_vocabularies_on_entry_and_vocabulary'
  end
end
