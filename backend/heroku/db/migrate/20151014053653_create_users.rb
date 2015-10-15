class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.index  :email, unique:true
      t.string :password

      t.timestamps
    end
  end
end
