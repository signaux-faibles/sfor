# frozen_string_literal: true

class Import < ApplicationRecord
  validates :name, presence: true
  validates :import_date, presence: true
  validates :data_freshness, presence: true
end
