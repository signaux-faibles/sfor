class ChartsController < ApplicationController
  def index; end

  def line_data
    render json: {
      x: [1, 2, 3, 4],
      y: [10, 20, 30, 40]
    }
  end

  def bar_data
    render json: {
      x: ["Produit A", "Produit B", "Produit C", "Produit D"],
      y: [50, 70, 30, 90],
      name: ["Ventes"],
      selected_palette: "neutral",
      highlight_index: [3],
      horizontal: true,
      unit_tooltip: "k€"
    }
  end
end
