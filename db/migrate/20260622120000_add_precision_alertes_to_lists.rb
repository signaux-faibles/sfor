# frozen_string_literal: true

class AddPrecisionAlertesToLists < ActiveRecord::Migration[7.2]
  def change
    add_column :lists, :precision_alerte_elevee, :decimal, precision: 5, scale: 2
    add_column :lists, :precision_alerte_moderee, :decimal, precision: 5, scale: 2
  end
end
