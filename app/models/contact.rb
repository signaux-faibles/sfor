class Contact < ApplicationRecord
  belongs_to :establishment
  include Discard::Model

  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
end
