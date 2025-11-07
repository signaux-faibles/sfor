import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenType", "hiddenCode", "hiddenLabel"]
  static values = { debounce: Number }

  connect() {
    this.debounceTimeout = null
    this.debounceDelay = this.hasDebounceValue ? this.debounceValue : 300
    this.selectedResult = null
    this.resultsContainer = {}
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  search() {
    const query = this.inputTarget.value.trim()

    // Clear previous timeout
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    // Clear results if query is empty
    if (query === "") {
      this.clearResults()
      return
    }

    // Debounce the search
    this.debounceTimeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceDelay)
  }

  async performSearch(query) {
    // Check if query is only numbers (department code)
    const isNumericOnly = /^\d+$/.test(query)

    try {
      if (isNumericOnly) {
        // Only search departments by code
        await this.searchDepartmentsByCode(query)
      } else {
        // Search all 4 endpoints in parallel
        await Promise.all([
          this.searchCommunes(query),
          this.searchDepartments(query),
          this.searchEpcis(query),
          this.searchRegions(query)
        ])
      }
    } catch (error) {
      console.error("Error performing geo search:", error)
      this.displayError("Une erreur est survenue lors de la recherche")
    }
  }

  async searchCommunes(query) {
    try {
      const url = `https://geo.api.gouv.fr/communes?fields=code,codesPostaux,departement&format=json&nom=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const data = await response.json()
      
      if (Array.isArray(data) && data.length > 0) {
        this.displayResults(data.map(item => ({
          type: "insee",
          code: item.code || "",
          label: `${item.nom} (${item.codesPostaux?.[0] || ""})`,
          fullLabel: item.nom,
          postalCode: item.codesPostaux?.[0] || "",
          department: item.departement
        })), "communes")
      }
    } catch (error) {
      console.error("Error searching communes:", error)
    }
  }

  async searchDepartments(query) {
    try {
      const url = `https://geo.api.gouv.fr/departements?fields=code&format=json&zone=metro,drom,com&nom=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const data = await response.json()
      
      if (Array.isArray(data) && data.length > 0) {
        this.displayResults(data.map(item => ({
          type: "dep",
          code: item.code,
          label: `${item.nom} (${item.code})`,
          fullLabel: item.nom
        })), "departements")
      }
    } catch (error) {
      console.error("Error searching departments:", error)
    }
  }

  async searchDepartmentsByCode(code) {
    try {
      const url = `https://geo.api.gouv.fr/departements?fields=code&format=json&zone=metro,drom,com&code=${encodeURIComponent(code)}`
      const response = await fetch(url)
      const data = await response.json()
      
      if (Array.isArray(data) && data.length > 0) {
        this.displayResults(data.map(item => ({
          type: "dep",
          code: item.code,
          label: `${item.nom} (${item.code})`,
          fullLabel: item.nom
        })), "departements")
      }
    } catch (error) {
      console.error("Error searching departments by code:", error)
    }
  }

  async searchEpcis(query) {
    try {
      const url = `https://geo.api.gouv.fr/epcis?fields=nom,code&nom=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const data = await response.json()
      
      if (Array.isArray(data) && data.length > 0) {
        this.displayResults(data.map(item => ({
          type: "epci",
          code: item.code,
          label: `${item.nom} (EPCI)`,
          fullLabel: item.nom
        })), "epcis")
      }
    } catch (error) {
      console.error("Error searching epcis:", error)
    }
  }

  async searchRegions(query) {
    try {
      const url = `https://geo.api.gouv.fr/regions?fields=nom,code&nom=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const data = await response.json()
      
      if (Array.isArray(data) && data.length > 0) {
        this.displayResults(data.map(item => ({
          type: "reg",
          code: item.code,
          label: item.nom,
          fullLabel: item.nom
        })), "regions")
      }
    } catch (error) {
      console.error("Error searching regions:", error)
    }
  }

  displayResults(results, category) {
    if (!this.resultsTarget) return

    // Store results by category
    this.resultsContainer[category] = results

    // Render all results
    this.renderAllResults()
  }

  renderAllResults() {
    if (!this.resultsTarget) return

    const allResults = []
    
    // Combine all results in order: communes, departments, epcis, regions
    const categories = ["communes", "departements", "epcis", "regions"]
    
    categories.forEach(category => {
      if (this.resultsContainer && this.resultsContainer[category]) {
        this.resultsContainer[category].forEach(result => {
          allResults.push({ ...result, category })
        })
      }
    })

    if (allResults.length === 0) {
      this.resultsTarget.innerHTML = '<div class="fr-alert fr-alert--info fr-mt-2w"><p>Aucun résultat trouvé.</p></div>'
      return
    }

    // Group by category for better display
    let html = '<div class="geo-search-results fr-mt-2w">'
    
    categories.forEach(category => {
      const categoryResults = allResults.filter(r => r.category === category)
      if (categoryResults.length > 0) {
        const categoryLabel = {
          communes: "Communes",
          departements: "Départements",
          epcis: "EPCI",
          regions: "Régions"
        }[category] || category

        html += `<div class="geo-search-category fr-mb-2w">`
        html += `<h4 class="fr-h6">${categoryLabel}</h4>`
        html += `<ul class="fr-list">`
        
        categoryResults.forEach(result => {
          html += `<li class="geo-search-result-item">`
          html += `<button type="button" class="fr-btn fr-btn--tertiary-no-outline fr-btn--sm" `
          html += `data-action="click->geo-search#selectResult" `
          html += `data-result-type="${result.type}" `
          html += `data-result-code="${result.code}" `
          html += `data-result-label="${this.escapeHtml(result.label)}" `
          html += `data-result-full-label="${this.escapeHtml(result.fullLabel)}">`
          html += `${this.escapeHtml(result.label)}`
          html += `</button>`
          html += `</li>`
        })
        
        html += `</ul>`
        html += `</div>`
      }
    })

    html += '</div>'
    this.resultsTarget.innerHTML = html
  }

  selectResult(event) {
    const type = event.currentTarget.dataset.resultType
    const code = event.currentTarget.dataset.resultCode
    const label = event.currentTarget.dataset.resultLabel
    const fullLabel = event.currentTarget.dataset.resultFullLabel

    // Update hidden fields
    if (this.hasHiddenTypeTarget) {
      this.hiddenTypeTarget.value = type
    }
    if (this.hasHiddenCodeTarget) {
      this.hiddenCodeTarget.value = code
    }
    if (this.hasHiddenLabelTarget) {
      this.hiddenLabelTarget.value = fullLabel
    }

    // Update input field with selected label
    this.inputTarget.value = label

    // Clear results
    this.clearResults()

    // Store selected result
    this.selectedResult = { type, code, label: fullLabel }
  }

  clearResults() {
    if (this.resultsTarget) {
      this.resultsTarget.innerHTML = ""
    }
    this.resultsContainer = {}
  }

  clearSelection() {
    this.inputTarget.value = ""
    this.clearResults()
    if (this.hasHiddenTypeTarget) {
      this.hiddenTypeTarget.value = ""
    }
    if (this.hasHiddenCodeTarget) {
      this.hiddenCodeTarget.value = ""
    }
    if (this.hasHiddenLabelTarget) {
      this.hiddenLabelTarget.value = ""
    }
    this.selectedResult = null
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  displayError(message) {
    if (this.resultsTarget) {
      this.resultsTarget.innerHTML = `<div class="fr-alert fr-alert--error fr-mt-2w"><p>${message}</p></div>`
    }
  }
}

