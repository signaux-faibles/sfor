class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_join_table :notifications, :segments do |t|
      t.index %i[notification_id segment_id], unique: true
    end

    create_table :notification_reads do |t|
      t.references :notification, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at

      t.timestamps
    end

    add_index :notification_reads, %i[notification_id user_id], unique: true
  end
end
