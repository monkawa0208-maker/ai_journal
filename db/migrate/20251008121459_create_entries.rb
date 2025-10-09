class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.date :posted_on, null: false
      t.text :response  
      
      t.timestamps
    end
    
    add_index :entries, [:user_id, :posted_on], unique: true
    add_index :entries, :posted_on
  end
end
