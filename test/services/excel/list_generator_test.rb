# frozen_string_literal: true

require "test_helper"
require "nokogiri"
require "zip"

module Excel
  class ListGeneratorTest < ActiveSupport::TestCase
    test "exports tracking status from companies.tracking_status" do
      company = companies(:company_paris)
      list = lists(:list_test_2025)

      rows = generated_rows(list, company)

      assert_equal "Accompagnement", rows.first[25]
      assert_equal "Accompagnement en cours", rows.second[25]
    end

    test "exports macro_expl score breakdown columns from company_lists" do
      company = companies(:company_paris)
      list = lists(:list_test_2025)

      rows = generated_rows(list, company)

      assert_equal Companies::MacroExplGroups.excel_headers, rows.first[16, 6]
      assert_equal %w[12 8 90 70 60 80], rows.second[16, 6]
    end

    test "exports latest INPI BCE ratios for each company" do
      company = companies(:company_paris)
      list = lists(:list_test_2025)

      create_inpi_bce_ratios(company)
      rows = generated_rows(list, company)

      assert_equal "Taux endettement", rows.first[26]
      assert_equal "CA", rows.first[27]
      assert_equal "Résultat net", rows.first[28]
      assert_equal "Résultat d'exploitation", rows.first[29]
      assert_equal "Ratio de liquidité", rows.first[30]
      assert_equal "45.12", rows.second[26]
      assert_equal "1234567", rows.second[27]
      assert_equal "-12345", rows.second[28]
      assert_equal "67890", rows.second[29]
      assert_equal "98.77", rows.second[30]
    end

    private

    def create_inpi_bce_ratios(company)
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
    end

    def generated_rows(list, company)
      xlsx = ListGenerator.new(
        list,
        Company.where(siren: company.siren),
        {},
        users(:user_crp_paris)
      ).generate

      worksheet_rows(xlsx)
    end

    def worksheet_rows(xlsx)
      rows = nil

      Zip::File.open_buffer(StringIO.new(xlsx)) do |zip_file|
        sheet_xml = zip_file.read("xl/worksheets/sheet1.xml")
        document = Nokogiri::XML(sheet_xml)
        document.remove_namespaces!

        rows = document.xpath("//sheetData/row").map do |row|
          row.xpath("c").map { |cell| cell_value(cell) }
        end
      end

      rows
    end

    def cell_value(cell)
      if cell["t"] == "inlineStr"
        cell.at_xpath("is/t")&.text
      else
        cell.at_xpath("v")&.text
      end
    end
  end
end
