class OsfDelai < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret, optional: true

  validates :siret, presence: true, length: { is: 14 }

  def self.active_dette_urssaf?(siret)
    # Find the last debit entry (is_last: true) for this siret
    debit = OsfDebit.where(siret: siret, is_last: true).first

    # If no entry found, no active dette
    return false unless debit

    # Check if at least one of the dettes is positive
    debit.part_ouvriere.to_f.positive? || debit.part_patronale.to_f.positive?
  end
end
