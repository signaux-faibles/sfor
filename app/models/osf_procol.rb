class OsfProcol < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: true

  validates :siren, presence: true, length: { is: 9 }
end
