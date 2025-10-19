class CreateVocabularies < ActiveRecord::Migration[7.1]
  def change
    create_table :vocabularies do |t|
      t.string :word, null: false, comment: '英単語'
      t.text :meaning, null: false, comment: '日本語の意味'
      t.boolean :mastered, default: false, null: false, comment: '習得済みフラグ'
      t.boolean :favorited, default: false, null: false, comment: 'お気に入りフラグ'
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'

      t.timestamps
    end

    add_index :vocabularies, [:user_id, :word], unique: true, name: 'index_vocabularies_on_user_id_and_word'
  end
end
