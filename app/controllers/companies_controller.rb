class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show]

  def index
    @q = Company.ransack(params[:q])

    @lists = List.all
    @latest_list = @lists.order(created_at: :desc).first

    params[:q] ||= {}
    if params[:q][:lists_id_eq].blank? && @latest_list
      params[:q][:lists_id_eq] = @latest_list.id
      @q = Company.ransack(params[:q])
    end

    @companies = @q.result(distinct: true)
    @campaigns = Campaign.all
    @departments = Department.all
    @activity_sectors = ActivitySector.all
    @lists = List.all
  end

  def show
    @establishments = @company.establishments_ordered
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end
end