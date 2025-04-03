# frozen_string_literal: true

# Validates network memberships for User models
# Ensures users belong to either one or two networks, with specific rules for CODEFI network
module User::NetworkValidatable
  extend ActiveSupport::Concern

  included do
    validate :validate_network_memberships
  end

  private

  def validate_network_memberships
    validate_network_count
    validate_network_combinations if networks.any?
  end

  def validate_network_count
    return if networks.size.between?(1, 2)

    errors.add(:networks, "Un utilisateur ne peut appartenir qu'à un ou deux réseaux")
  end

  def validate_network_combinations
    case networks.size
    when 1
      validate_single_network
    when 2
      validate_dual_networks
    end
  end

  def validate_single_network
    return unless networks.first.name == "CODEFI"

    errors.add(:networks, "Un utilisateur ne peut pas appartenir uniquement au réseau CODEFI")
  end

  def validate_dual_networks
    return if networks.any? { |network| network.name == "CODEFI" }

    errors.add(:networks, "Si un utilisateur appartient à deux réseaux, l'un d'eux doit être CODEFI")
  end
end
