class Entity < ApplicationRecord
  has_many :users, dependent: :nullify
end
