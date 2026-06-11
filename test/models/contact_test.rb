# frozen_string_literal: true

require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "invalid email uses accessible error message with example" do
    contact = Contact.new(
      establishment: establishments(:establishment_paris),
      first_name: "Jean",
      last_name: "Dupont",
      email: "adresse-invalide"
    )

    assert_not contact.valid?
    assert_includes contact.errors[:email],
                    "Veuillez saisir une adresse e-mail valide, par exemple : john.doe@signaux-faibles.gouv.fr"
  end
end
