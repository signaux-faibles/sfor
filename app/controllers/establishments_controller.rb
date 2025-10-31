class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    load_trackings
  end

  def insee_widget
    @establishment = Establishment.find_by!(siret: params[:siret])
    fetch_insee_data
    render partial: "insee_widget"
  end

  def data_urssaf_widget
    periodes = [
      "2023-09-01T00:00:00Z",
      "2023-10-01T00:00:00Z",
      "2023-11-01T00:00:00Z",
      "2023-12-01T00:00:00Z",
      "2024-01-01T00:00:00Z",
      "2024-02-01T00:00:00Z",
      "2024-03-01T00:00:00Z",
      "2024-04-01T00:00:00Z",
      "2024-05-01T00:00:00Z",
      "2024-06-01T00:00:00Z",
      "2024-07-01T00:00:00Z",
      "2024-08-01T00:00:00Z",
      "2024-09-01T00:00:00Z",
      "2024-10-01T00:00:00Z",
      "2024-11-01T00:00:00Z",
      "2024-12-01T00:00:00Z",
      "2025-01-01T00:00:00Z",
      "2025-02-01T00:00:00Z",
      "2025-03-01T00:00:00Z",
      "2025-04-01T00:00:00Z",
      "2025-05-01T00:00:00Z",
      "2025-06-01T00:00:00Z",
      "2025-07-01T00:00:00Z",
      "2025-08-01T00:00:00Z"
    ]

    @formatted_periodes = periodes.map do |date|
      d = Date.parse(date)
      I18n.l(d, format: '%B %Y', locale: :fr).capitalize
    end

    @cotisations = [
      5291.58349609375,
      5056.58349609375,
      5749.58349609375,
      4647.58349609375,
      2103,
      1818,
      1341,
      2259,
      2378,
      2149,
      2935,
      2948,
      2921,
      3608,
      2365,
      2718,
      2946,
      2835,
      3031,
      3733,
      5440,
      4576,
      3873
    ]

    @parts_patronales = [
      54478,
      56548,
      58645,
      60639,
      62570,
      64281,
      67293,
      67293,
      68576,
      68576,
      69708,
      69708,
      69708,
      69708,
      68868.765625,
      67736.765625,
      67736.765625,
      69438.765625,
      69438.765625,
      69438.765625,
      68526.765625,
      68526.765625,
      66823.765625,
      64823.76171875
    ]

    @parts_salariales = [
      36898,
      38358,
      39930,
      40987,
      41872,
      43670,
      45168,
      45168,
      45703,
      45703,
      46830,
      46830,
      46830,
      46830,
      46830,
      45703,
      45703,
      46365,
      46365,
      46365,
      47252,
      47252,
      46590,
      46590
    ]

    @montant_echeancier = [
      4523,
      3891,
      2456,
      4102,
      3287,
      4789,
      2134,
      3654,
      4421,
      2987,
      3156,
      4678,
      2543,
      3912,
      4234,
      2876,
      3534,
      4567,
      2298,
      3789,
      4345,
      2654,
      3423,
      4891
    ]

    @dataset_names = [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget
    periodes = [
      "2023-09-01T00:00:00Z",
      "2023-10-01T00:00:00Z",
      "2023-11-01T00:00:00Z",
      "2023-12-01T00:00:00Z",
      "2024-01-01T00:00:00Z",
      "2024-02-01T00:00:00Z",
      "2024-03-01T00:00:00Z",
      "2024-04-01T00:00:00Z",
      "2024-05-01T00:00:00Z",
      "2024-06-01T00:00:00Z",
      "2024-07-01T00:00:00Z",
      "2024-08-01T00:00:00Z",
      "2024-09-01T00:00:00Z",
      "2024-10-01T00:00:00Z",
      "2024-11-01T00:00:00Z",
      "2024-12-01T00:00:00Z",
      "2025-01-01T00:00:00Z",
      "2025-02-01T00:00:00Z",
      "2025-03-01T00:00:00Z",
      "2025-04-01T00:00:00Z",
      "2025-05-01T00:00:00Z",
      "2025-06-01T00:00:00Z",
      "2025-07-01T00:00:00Z"
    ]

    @formatted_periodes = periodes.map do |date|
      d = Date.parse(date)
      I18n.l(d, format: '%B %Y', locale: :fr).capitalize
    end

    data_consommation_ap = [
      {
        "idConso": "59L78530100",
        "heureConsomme": 10407.1796875,
        "montant": 122462.7265625,
        "effectif": 221,
        "date": "2020-03-01T00:00:00Z"
      },
      {
        "idConso": "59L78530100",
        "heureConsomme": 40456.640625,
        "montant": 477885.4375,
        "effectif": 279,
        "date": "2020-04-01T00:00:00Z"
      },
      {
        "idConso": "59L78530100",
        "heureConsomme": 12401.0595703125,
        "montant": 156530.09375,
        "effectif": 247,
        "date": "2020-05-01T00:00:00Z"
      },
      {
        "idConso": "59L78530100",
        "heureConsomme": 615.6500244140625,
        "montant": 5700.52001953125,
        "effectif": 10,
        "date": "2020-06-01T00:00:00Z"
      },
      {
        "idConso": "59L78530100",
        "heureConsomme": 438.3299865722656,
        "montant": 3468.10009765625,
        "effectif": 4,
        "date": "2020-07-01T00:00:00Z"
      },
      {
        "idConso": "59L78530100",
        "heureConsomme": 158.3300018310547,
        "montant": 1251.4599609375,
        "effectif": 2,
        "date": "2020-08-01T00:00:00Z"
      },
      {
        "idConso": "59L78530200",
        "heureConsomme": 266,
        "montant": 2708.22998046875,
        "effectif": 6,
        "date": "2021-04-01T00:00:00Z"
      },
      {
        "idConso": "59L78530401",
        "heureConsomme": 35,
        "montant": 263.54998779296875,
        "effectif": 1,
        "date": "2022-03-01T00:00:00Z"
      },
      {
        "idConso": "59L78530702",
        "heureConsomme": 728.489990234375,
        "montant": 8199.6904296875,
        "effectif": 124,
        "date": "2023-06-01T00:00:00Z"
      },
      {
        "idConso": "59L78530702",
        "heureConsomme": 5.670000076293945,
        "montant": 52.619998931884766,
        "effectif": 1,
        "date": "2023-07-01T00:00:00Z"
      },
      {
        "idConso": "59L78530702",
        "heureConsomme": 13.010000228881836,
        "montant": 118.6500015258789,
        "effectif": 1,
        "date": "2023-08-01T00:00:00Z"
      },
      {
        "idConso": "59L78530702",
        "heureConsomme": 264.5899963378906,
        "montant": 2598.2900390625,
        "effectif": 26,
        "date": "2023-09-01T00:00:00Z"
      },
      {
        "idConso": "59L78530702",
        "heureConsomme": 17.010000228881836,
        "montant": 157.9600067138672,
        "effectif": 3,
        "date": "2023-10-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 145.02999877929688,
        "montant": 1420.9100341796875,
        "effectif": 14,
        "date": "2023-11-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 968.2000122070312,
        "montant": 10508.8896484375,
        "effectif": 88,
        "date": "2023-12-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 167.3000030517578,
        "montant": 1567.010009765625,
        "effectif": 46,
        "date": "2024-01-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 5.670000076293945,
        "montant": 52.279998779296875,
        "effectif": 1,
        "date": "2024-02-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 378.0799865722656,
        "montant": 3562.199951171875,
        "effectif": 9,
        "date": "2024-03-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 165.02000427246094,
        "montant": 1542.22998046875,
        "effectif": 8,
        "date": "2024-04-01T00:00:00Z"
      },
      {
        "idConso": "59L78530703",
        "heureConsomme": 295.5199890136719,
        "montant": 3095.159912109375,
        "effectif": 38,
        "date": "2024-05-01T00:00:00Z"
      },
      {
        "idConso": "59L78530704",
        "heureConsomme": 108,
        "montant": 999.27001953125,
        "effectif": 4,
        "date": "2024-06-01T00:00:00Z"
      },
      {
        "idConso": "59L78530704",
        "heureConsomme": 30.889999389648438,
        "montant": 288.05999755859375,
        "effectif": 4,
        "date": "2024-07-01T00:00:00Z"
      },
      {
        "idConso": "59L78530705",
        "heureConsomme": 224.3300018310547,
        "montant": 3864.199951171875,
        "effectif": 32,
        "date": "2024-10-01T00:00:00Z"
      },
      {
        "idConso": "59L78530705",
        "heureConsomme": 173.66000366210938,
        "montant": 2977.10009765625,
        "effectif": 25,
        "date": "2024-11-01T00:00:00Z"
      },
      {
        "idConso": "59L78530706",
        "heureConsomme": 427,
        "montant": 7289.8701171875,
        "effectif": 29,
        "date": "2024-12-01T00:00:00Z"
      },
      {
        "idConso": "59L78530706",
        "heureConsomme": 1119.760009765625,
        "montant": 13013.9296875,
        "effectif": 196,
        "date": "2025-02-01T00:00:00Z"
      }
    ]

    @consommation_ap = periodes.map do |periode|
      entry = data_consommation_ap.find { |item| item[:date] == periode }
      entry ? entry[:effectif] : 0
    end

    data_autorisation_ap = [
      {
        "idDemande": "S59L080467",
        "effectifEntreprise": 676,
        "effectif": 676,
        "effectifAutorise": 4,
        "dateStatut": "2008-12-30T00:00:00Z",
        "debut": "2008-12-01T00:00:00Z",
        "fin": "2008-12-31T00:00:00Z",
        "hta": 420,
        "mta": 894.5999755859375,
        "motifRecoursSE": 1,
        "heureConsomme": 63,
        "montantConsomme": 134.19000244140625,
        "effectifConsomme": 4
      },
      {
        "idDemande": "S59L090262",
        "effectifEntreprise": 676,
        "effectif": 676,
        "effectifAutorise": 316,
        "dateStatut": "2009-04-03T00:00:00Z",
        "debut": "2009-01-02T00:00:00Z",
        "fin": "2009-03-31T00:00:00Z",
        "hta": 17500,
        "mta": 58275,
        "motifRecoursSE": 1,
        "heureConsomme": 10202,
        "montantConsomme": 33974.328125,
        "effectifConsomme": 250
      },
      {
        "idDemande": "S59L120019",
        "effectifEntreprise": 704,
        "effectif": 622,
        "effectifAutorise": 245,
        "dateStatut": "2012-03-14T00:00:00Z",
        "debut": "2012-01-28T00:00:00Z",
        "fin": "2012-04-28T00:00:00Z",
        "hta": 36015,
        "mta": 119929.953125,
        "motifRecoursSE": 1,
        "heureConsomme": 0,
        "montantConsomme": 0,
        "effectifConsomme": 0
      },
      {
        "idDemande": "S59L120210",
        "effectifEntreprise": 692,
        "effectif": 625,
        "effectifAutorise": 555,
        "dateStatut": "2012-04-16T00:00:00Z",
        "debut": "2012-03-06T00:00:00Z",
        "fin": "2012-03-08T00:00:00Z",
        "hta": 11655,
        "mta": 50466.1484375,
        "motifRecoursSE": 2,
        "heureConsomme": 5760,
        "montantConsomme": 24943.609375,
        "effectifConsomme": 396
      },
      {
        "idDemande": "S59L120496",
        "effectifEntreprise": 662,
        "effectif": 635,
        "effectifAutorise": 635,
        "dateStatut": "2012-12-11T00:00:00Z",
        "debut": "2012-12-10T00:00:00Z",
        "fin": "2013-02-28T00:00:00Z",
        "hta": 111125,
        "mta": 481171.25,
        "motifRecoursSE": 1,
        "heureConsomme": 11765,
        "montantConsomme": 50946.76953125,
        "effectifConsomme": 285
      },
      {
        "idDemande": "S59L130144",
        "effectifEntreprise": 656,
        "effectif": 631,
        "effectifAutorise": 631,
        "dateStatut": "2013-02-22T00:00:00Z",
        "debut": "2013-03-01T00:00:00Z",
        "fin": "2013-05-31T00:00:00Z",
        "hta": 22085,
        "mta": 95628.046875,
        "motifRecoursSE": 1,
        "heureConsomme": 3118,
        "montantConsomme": 13503.099609375,
        "effectifConsomme": 313
      },
      {
        "idDemande": "59L78530100",
        "effectifEntreprise": 809,
        "effectif": 311,
        "effectifAutorise": 331,
        "dateStatut": "2020-03-26T00:00:00Z",
        "debut": "2020-03-17T00:00:00Z",
        "fin": "2020-09-17T00:00:00Z",
        "hta": 294259,
        "mta": nil,
        "motifRecoursSE": 5,
        "heureConsomme": 64477.19140625,
        "montantConsomme": 767298.3125,
        "effectifConsomme": 825
      },
      {
        "idDemande": "59L78530200",
        "effectifEntreprise": 809,
        "effectif": 311,
        "effectifAutorise": 10,
        "dateStatut": "2021-06-01T00:00:00Z",
        "debut": "2021-04-06T00:00:00Z",
        "fin": "2021-05-02T00:00:00Z",
        "hta": 550,
        "mta": nil,
        "motifRecoursSE": 5,
        "heureConsomme": 266,
        "montantConsomme": 2708.22998046875,
        "effectifConsomme": 6
      },
      {
        "idDemande": "59L78530401",
        "effectifEntreprise": 809,
        "effectif": 311,
        "effectifAutorise": 275,
        "dateStatut": "2022-04-01T00:00:00Z",
        "debut": "2021-12-24T00:00:00Z",
        "fin": "2022-06-23T00:00:00Z",
        "hta": 5000,
        "mta": nil,
        "motifRecoursSE": 5,
        "heureConsomme": 35,
        "montantConsomme": 263.54998779296875,
        "effectifConsomme": 1
      },
      {
        "idDemande": "59L78530600",
        "effectifEntreprise": 809,
        "effectif": 311,
        "effectifAutorise": 320,
        "dateStatut": "2022-06-28T00:00:00Z",
        "debut": "2022-07-01T00:00:00Z",
        "fin": "2022-12-31T00:00:00Z",
        "hta": 66555,
        "mta": nil,
        "motifRecoursSE": 7,
        "heureConsomme": nil,
        "montantConsomme": nil,
        "effectifConsomme": nil
      },
      {
        "idDemande": "59L78530707",
        "effectifEntreprise": 809,
        "effectif": 311,
        "effectifAutorise": 273,
        "dateStatut": "2025-04-25T00:00:00Z",
        "debut": "2023-01-01T00:00:00Z",
        "fin": "2025-09-30T00:00:00Z",
        "hta": 49682,
        "mta": nil,
        "motifRecoursSE": 7,
        "heureConsomme": nil,
        "montantConsomme": nil,
        "effectifConsomme": nil
      }
    ]

    @autorisation_ap = periodes.map do |periode|
      periode_date = Date.parse(periode)

      entry = data_autorisation_ap.find do |item|
        next if item[:debut].nil? || item[:fin].nil?

        debut = Date.parse(item[:debut])
        fin = Date.parse(item[:fin])
        periode_date >= debut && periode_date <= fin
      end

      entry ? entry[:effectifAutorise] : 0
    end

    @effectifs = [
      290,
      290,
      289,
      288,
      288,
      284,
      282,
      281,
      277,
      276,
      271,
      267,
      266,
      264,
      265,
      264,
      260,
      255,
      253,
      250,
      252,
      251,
      249
    ]

    @dataset_names = [
      "Effectifs (salariés)",
      "Consommation activité partielle (ETP)",
      "Autorisation activité partielle (salariés)",
    ]

    render partial: "data_effectif_ap_widget"
  end

  def new
    @establishment = Establishment.find_by(siret: params[:establishment_siret])
    if @establishment
      @establishment_tracking = EstablishmentTracking.new(establishment: @establishment)
      # Autres initialisations si nécessaire
    else
      redirect_to some_path, alert: t("establishments.not_found")
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find_by!(siret: params[:siret])
  end

  def load_trackings
    @in_progress_trackings = load_trackings_by_state(:in_progress)
    @completed_trackings = load_trackings_by_state(:completed)
    @under_surveillance_trackings = load_trackings_by_state(:under_surveillance)
  end

  def load_trackings_by_state(state)
    policy_scope(@establishment.establishment_trackings)
      .includes(:creator, :criticality, :referents)
      .send(state)
      .order(start_date: :asc)
  end

  def fetch_insee_data
    return if @establishment.siret.blank?

    service = Api::InseeApiService.new
    @insee_data = service.fetch_establishment_by_siret(@establishment.siret)

    siren = @insee_data&.dig("data", "unite_legale", "siren")
    @company_insee_data = service.fetch_unite_legale_by_siren(siren) if siren.present?

    date_fermeture = @insee_data&.dig("data", "date_fermeture")
    @date_fermeture_formatted = Time.at(date_fermeture).to_date.strftime("%d/%m/%Y") if date_fermeture.present?

  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données INSEE: #{e.message}"
    @insee_data = nil
  end
end
