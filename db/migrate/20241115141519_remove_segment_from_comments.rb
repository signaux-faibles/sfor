class RemoveSegmentFromComments < ActiveRecord::Migration[7.1]
  def change
    remove_reference :comments, :segment, foreign_key: true
  end
end
