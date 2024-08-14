class AddEntityAndSegmentToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :entity, null: false, foreign_key: true
    add_reference :users, :segment, null: false, foreign_key: true
  end
end
