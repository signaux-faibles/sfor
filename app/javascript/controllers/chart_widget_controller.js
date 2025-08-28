import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, chartType: String }

  connect() {
    console.log("Chart widget controller connected")
    this.loadChart()
  }

  disconnect() {
    console.log("Chart widget controller disconnected")
    this.clearChart()
  }

  async loadChart() {
    try {
      console.log(`Loading chart data from: ${this.urlValue}`)
      
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log(`Chart data received:`, data)
      
      this.createChart(data)
      
    } catch (error) {
      console.error('Error loading chart:', error)
      this.showError(`Erreur lors du chargement: ${error.message}`)
    }
  }

  createChart(data) {
    this.clearChart()
    
    let chartElement
    
    if (this.chartTypeValue === 'line') {
      chartElement = document.createElement('line-chart')
      chartElement.setAttribute('x', JSON.stringify([data.x]))
      chartElement.setAttribute('y', JSON.stringify([data.y]))
    } else if (this.chartTypeValue === 'bar') {
      chartElement = document.createElement('bar-chart')
      chartElement.setAttribute('x', JSON.stringify([data.x]))
      chartElement.setAttribute('y', JSON.stringify([data.y]))
      
      if (data.name) chartElement.setAttribute('name', JSON.stringify(data.name))
      if (data.selected_palette) chartElement.setAttribute('selected-palette', data.selected_palette)
      if (data.highlight_index) chartElement.setAttribute('highlight-index', JSON.stringify(data.highlight_index))
      if (data.horizontal) chartElement.setAttribute('horizontal', data.horizontal)
      if (data.unit_tooltip) chartElement.setAttribute('unit-tooltip', data.unit_tooltip)
    }

    this.element.appendChild(chartElement)
    console.log(`${this.chartTypeValue} chart created successfully`)
  }

  clearChart() {
    this.element.innerHTML = ''
  }

  showError(message) {
    this.element.innerHTML = `<div class="fr-alert fr-alert--error"><p>${message}</p></div>`
  }
}
