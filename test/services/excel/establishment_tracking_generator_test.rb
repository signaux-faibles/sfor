# frozen_string_literal: true

require "test_helper"
require "nokogiri"
require "zip"

module Excel
  class EstablishmentTrackingGeneratorTest < ActiveSupport::TestCase
    test "exports tracking rows with company raison sociale and preloaded summaries" do
      tracking = establishment_trackings(:establishment_tracking_paris)
      user = users(:user_crp_paris)

      rows = generated_rows(EstablishmentTracking.where(id: tracking.id), user)
      data_row = rows.second

      assert_equal "Raison sociale", rows.first[0]
      assert_equal "Company Paris", data_row[0]
      assert_equal "12345678900001", data_row[1]
      assert_equal "Paris", data_row[2]
      assert_equal "50", data_row[15]
      assert_equal "42", data_row[16]
      assert_equal "Dummy content", data_row[17]
      assert_equal "Aucune synthèse CODEFI rédigée", data_row[18]
    end

    test "export preload scope keeps query count stable as rows grow" do
      user = users(:user_crp_paris)
      tracking_ids = [
        establishment_trackings(:establishment_tracking_paris).id,
        establishment_trackings(:establishment_tracking_paris2).id
      ]

      single_scope = EstablishmentTracking.where(id: tracking_ids.first).includes(
        EstablishmentTrackingGenerator::EXPORT_INCLUDES
      )
      double_scope = EstablishmentTracking.where(id: tracking_ids).includes(
        EstablishmentTrackingGenerator::EXPORT_INCLUDES
      )

      single_queries = count_queries do
        EstablishmentTrackingGenerator.new(single_scope, EstablishmentTracking.ransack({}), user).generate
      end

      double_queries = count_queries do
        EstablishmentTrackingGenerator.new(double_scope, EstablishmentTracking.ransack({}), user).generate
      end

      assert_operator double_queries, :<=, single_queries + 2
    end

    private

    def generated_rows(scope, user)
      xlsx = EstablishmentTrackingGenerator.new(scope, EstablishmentTracking.ransack({}), user).generate
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

    def count_queries(&)
      count = 0
      counter = lambda do |_name, _started, _finished, _unique_id, payload|
        count += 1 unless payload[:name].in?(%w[CACHE SCHEMA])
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
      count
    end
  end
end
