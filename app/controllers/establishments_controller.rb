class EstablishmentsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ProcolStatusable
  include OutOfZoneTrackable
  include DebitFreshnessable
  include ForwardFillable

  before_action :set_establishment,
                only: %i[show data_effectif_ap_widget data_urssaf_widget establishment_trackings_list_widget]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    load_trackings
    @procol_status = calculate_procol_status
    track_out_of_zone_access(@establishment)
  end

  def insee_widget
    @establishment = Establishment.find_by!(siret: params[:siret])
    data = Establishments::InseeDataBuilder.new(@establishment).build
    @insee_data = data[:insee_data]
    @company_insee_data = data[:company_insee_data]
    @date_fermeture_formatted = data[:date_fermeture_formatted]
    render partial: "insee_widget"
  end

  def data_urssaf_widget
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = Companies::PeriodsBuilder.build(start_date)

    data = Establishments::UrssafSeriesBuilder.new(
      establishment: @establishment,
      start_date: start_date,
      periodes: periodes,
      debit_freshness_index: method(:debit_freshness_index),
      forward_fill: method(:forward_fill)
    ).build

    @cotisations = data[:cotisations]
    @parts_salariales = data[:parts_salariales]
    @parts_patronales = data[:parts_patronales]
    @montant_echeancier = data[:montant_echeancier]

    @dataset_names = urssaf_dataset_names

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = Companies::PeriodsBuilder.build(start_date)

    data = Establishments::EffectifApSeriesBuilder.new(
      establishment: @establishment,
      start_date: start_date,
      periodes: periodes
    ).build

    @effectifs = data[:effectifs]
    @consommation_ap = data[:consommation_ap]
    @autorisation_ap = data[:autorisation_ap]

    @dataset_names = effectif_ap_dataset_names

    render partial: "data_effectif_ap_widget"
  end

  def establishment_trackings_list_widget
    # load_trackings uses policy_scope via load_trackings_by_state
    load_trackings
    render partial: "establishment_trackings_list_widget"
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
    # Custom authorization logic:
    # 1. If the establishment is in user's departments, show all trackings
    # 2. If the establishment is not in user's departments but user is referent/participant, show all trackings
    # 3. Otherwise, show none
    all_establishment_trackings = @establishment.establishment_trackings

    can_see_trackings = false

    # Check if establishment is in user's departments
    can_see_trackings = true if current_user.department_ids.include?(@establishment.department&.id)

    # Check if user is referent or participant in any tracking of the establishment
    can_see_trackings = true if !can_see_trackings && all_establishment_trackings.with_user_as_referent_or_participant(current_user).exists?

    @can_see_trackings = can_see_trackings
    @has_any_trackings = all_establishment_trackings.exists?
    @authorized_trackings = can_see_trackings ? all_establishment_trackings : EstablishmentTracking.none

    @in_progress_trackings = load_trackings_by_state(:in_progress)
    @completed_trackings = load_trackings_by_state(:completed)
    @under_surveillance_trackings = load_trackings_by_state(:under_surveillance)
  end

  def load_trackings_by_state(state)
    @authorized_trackings
      .includes(:creator, :criticality, :referents)
      .send(state)
      .order(start_date: :asc)
  end

  def effectif_ap_dataset_names
    [
      "Effectifs (salariés)",
      "Consommation d'activité partielle (ETP)",
      "Autorisation d'activité partielle (ETP)"
    ]
  end

  def urssaf_dataset_names
    [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]
  end

  def calculate_procol_status
    procol_status_for_siren(@establishment.siren)
  end
end
