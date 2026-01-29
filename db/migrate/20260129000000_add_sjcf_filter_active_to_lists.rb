# frozen_string_literal: true

class AddSjcfFilterActiveToLists < ActiveRecord::Migration[7.1]
  def change
    add_column :lists, :sjcf_filter_active, :boolean, default: false, null: false
  end
end
