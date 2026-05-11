# frozen_string_literal: true

require "test_helper"
require "nokogiri"
require "zip"

module Excel
  class ListGeneratorTest < ActiveSupport::TestCase
    test "exports latest INPI BCE ratios for each company" do
      company = companies(:company_paris)
      list = lists(:list_test_2025)

      InpiBceRatio.create!(
        siren: company.siren,
        date_cloture_exercice: Date.new(2022, 12, 31),
        type_bilan: "C",
        chiffre_d_affaires: 900_000,
        resultat_net: 40_000,
        ebit: 70_000,
        taux_d_endettement: 12.5,
        ratio_de_liquidite: 110.25
      )
      InpiBceRatio.create!(
        siren: company.siren,
        date_cloture_exercice: Date.new(2023, 12, 31),
        type_bilan: "C",
        chiffre_d_affaires: 1_234_567,
        resultat_net: -12_345,
        ebit: 67_890,
        taux_d_endettement: 45.123456,
        ratio_de_liquidite: 98.765432
      )

      xlsx = ListGenerator.new(
        list,
        Company.where(siren: company.siren),
        {},
        users(:user_crp_paris)
      ).generate

      rows = worksheet_rows(xlsx)

      assert_equal "Taux endettement", rows.first[24]
      assert_equal "CA", rows.first[25]
      assert_equal "Résultat net", rows.first[26]
      assert_equal "Résultat d'exploitation", rows.first[27]
      assert_equal "Ratio de liquidité", rows.first[28]
      assert_equal "45.123456", rows.second[24]
      assert_equal "1234567", rows.second[25]
      assert_equal "-12345", rows.second[26]
      assert_equal "67890", rows.second[27]
      assert_equal "98.765432", rows.second[28]
    end

    private

    def worksheet_rows(xlsx)
      Zip::File.open_buffer(StringIO.new(xlsx)) do |zip_file|
        sheet_xml = zip_file.read("xl/worksheets/sheet1.xml")
        document = Nokogiri::XML(sheet_xml)
        namespace = { "x" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }

        document.xpath("//x:sheetData/x:row", namespace).map do |row|
          row.xpath("x:c", namespace).map { |cell| cell_value(cell, namespace) }
        end
      end
    end

    def cell_value(cell, namespace)
      if cell["t"] == "inlineStr"
        cell.at_xpath("x:is/x:t", namespace)&.text
      else
        cell.at_xpath("x:v", namespace)&.text
      end
    end
  end
end
