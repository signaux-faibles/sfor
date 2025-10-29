# frozen_string_literal: true

# Handles loading of summaries, comments, and related trackings
module EstablishmentTrackings::Loadable
  extend ActiveSupport::Concern

  private

  def load_summaries(user_network_ids)
    @summaries = Summary.where(establishment_tracking: @establishment_tracking, network_id: user_network_ids)
    @codefi_summaries = @summaries.includes([:network]).find { |s| s.network.name == "CODEFI" }
    @user_network_summaries = @summaries.find do |s|
      s.network.id == current_user.networks.where.not(name: "CODEFI").pick(:id)
    end
  end

  def load_comments(user_network_ids)
    @comments = Comment.includes(%i[network user])
                       .where(establishment_tracking: @establishment_tracking, network_id: user_network_ids)
                       .order(created_at: :desc)
    @codefi_comments = @comments.select { |c| c.network.name == "CODEFI" }
    @user_network_comments = @comments.select do |c|
      c.network.id == current_user.networks.where.not(name: "CODEFI").pick(:id)
    end
  end

  def load_related_trackings
    @other_trackings = @establishment_tracking.establishment.establishment_trackings
                                              .includes(:criticality, :referents)
                                              .where
                                              .not(id: @establishment_tracking.id)
    @company_trackings = EstablishmentTracking
                         .joins(:establishment)
                         .includes(:criticality, :referents)
                         .where(establishments: { siren: @establishment_tracking.establishment.siren })
                         .where.not(id: @establishment_tracking.id)
                         .distinct
  end
end
