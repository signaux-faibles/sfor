# frozen_string_literal: true

require "test_helper"

module Companies
  class MacroExplGroupsTest < ActiveSupport::TestCase
    test "normalize maps legacy Autres to Age-de-l'entreprise" do
      normalized = MacroExplGroups.normalize(
        "Autres" => 0.4,
        "Dettes-sociales" => 0.6
      )

      assert_in_delta 0.4, normalized["Age-de-l'entreprise"], 0.001
      assert_not normalized.key?("Autres")
    end

    test "normalize keeps canonical age when both legacy and canonical keys exist" do
      normalized = MacroExplGroups.normalize(
        "Autres" => 0.2,
        "Age-de-l'entreprise" => 0.6
      )

      assert_in_delta 0.6, normalized["Age-de-l'entreprise"], 0.001
      assert_not normalized.key?("Autres")
    end

    test "macro_expl_value_sql coalesces legacy and canonical age keys" do
      entry = MacroExplGroups::ALL.find { |group| group.score_column == :score_age }
      sql = MacroExplGroups.macro_expl_value_sql(entry)

      assert_includes sql, "COALESCE"
      assert_includes sql, "Autres"
      assert_includes sql, "Age-de-l"
    end
  end
end
