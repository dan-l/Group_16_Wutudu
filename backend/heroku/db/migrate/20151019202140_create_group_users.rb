class CreateGroupUsers < ActiveRecord::Migration
  def change
    create_table :group_users do |t|
      t.references :group, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.boolean :approved

      t.timestamps null: false
    end
  end
end
