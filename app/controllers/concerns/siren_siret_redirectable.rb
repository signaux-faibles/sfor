# frozen_string_literal: true

# Handles redirect logic when search query is a valid SIREN or SIRET
module SirenSiretRedirectable
  extend ActiveSupport::Concern

  private

  def redirect_if_siren_or_siret(query)
    return if query.blank?

    cleaned_query = query.to_s.gsub(/\D/, "")

    # Only redirect if the original query contains ONLY digits (possibly with spaces/formatting)
    # If it contains letters or other text, we will treat it as a raison_sociale search
    original_without_spaces = query.to_s.gsub(/[\s\-\.]/, "")
    return if original_without_spaces != cleaned_query

    if cleaned_query.length == 14
      establishment = Establishment.find_by(siret: cleaned_query)
      return redirect_to establishment_path(establishment) if establishment
    end

    if cleaned_query.length == 9
      company = Company.find_by(siren: cleaned_query)
      redirect_to company_path(company) if company
    end
  end
end
