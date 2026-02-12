class AppSetting < ApplicationRecord
  validate :single_instance, on: :create

  def self.current
    order(updated_at: :desc).first
  end

  private

  def single_instance
    return unless AppSetting.exists?

    errors.add(:base, "Un seul paramètre est autorisé.")
  end
end
