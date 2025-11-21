class CompanyList < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :list

  validates :siren, presence: true, length: { is: 9 }
  validates :siren, uniqueness: { scope: :list_id }
end
