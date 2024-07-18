class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show]

  def index
    @q = Company.ransack(params[:q])
    @companies = @q.result(distinct: true)
    @campaigns = Campaign.all
    @departments = Department.all
    @activity_sectors = ActivitySector.all
    @lists = List.all
  end

  def show
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end
end