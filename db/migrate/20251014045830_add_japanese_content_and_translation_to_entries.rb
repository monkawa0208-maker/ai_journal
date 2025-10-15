class AddJapaneseContentAndTranslationToEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :entries, :content_ja, :text
    add_column :entries, :ai_translate, :text
  end
end
