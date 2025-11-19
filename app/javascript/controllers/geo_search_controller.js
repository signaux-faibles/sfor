import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenType", "hiddenCode", "hiddenLabel"]
  static values = { debounce: Number }

  connect() {
    this.debounceTimeout = null
    this.debounceDelay = this.hasDebounceValue ? this.debounceValue : 300
    this.selectedResult = null
    this.resultsContainer = {}
    this.focusedOptionIndex = -1
    this.allLocations = null // Will store all departments and regions
    this.loadAllLocations()
  }

  async loadAllLocations() {
    try {
      // Load all departments and regions
      const [departments, regions] = await Promise.all([
        fetch('https://geo.api.gouv.fr/departements?fields=nom,code&zone=metro,drom,com').then(r => r.json()),
        fetch('https://geo.api.gouv.fr/regions?fields=nom,code').then(r => r.json())
      ])

      this.allLocations = {
        departements: departments.map(item => ({
          type: "dep",
          code: item.code,
          label: `${item.nom} (${item.code})`,
          fullLabel: item.nom
        })),
        regions: regions.map(item => ({
          type: "reg",
          code: item.code,
          label: item.nom,
          fullLabel: item.nom
        }))
      }
    } catch (error) {
      console.error("Error loading all locations:", error)
      this.allLocations = { departements: [], regions: [] }
    }
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  handleKeydown(event) {
    console.log('Key pressed:', event.key, 'Alt:', event.altKey)
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      if (event.altKey) {
        console.log('Handling Alt+ArrowDown')
        this.handleAltArrowDown()
      } else {
        console.log('Handling ArrowDown')
        this.handleArrowDown()
      }
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.handleArrowUp()
    } else if (event.key === 'Enter') {
      event.preventDefault()
      this.handleEnter()
    } else if (event.key === 'Escape') {
      this.handleEscape()
    } else if (event.key === 'ArrowRight') {
      this.handleArrowRight()
    } else if (event.key === 'ArrowLeft') {
      this.handleArrowLeft()
    } else if (event.key === 'Home') {
      this.handleHome()
    } else if (event.key === 'End') {
      this.handleEnd()
    }
  }

  handleAltArrowDown() {
    // Opens the listbox without moving focus or changing selection
    const isListboxDisplayed = this.resultsTarget.querySelector('.geo-search-results') !== null

    // If listbox is already displayed, do nothing
    if (isListboxDisplayed) return

    const query = this.inputTarget.value.trim()

    if (query === "") {
      // If textbox is empty, display all locations
      this.displayAllLocations()
    } else {
      // If there's a query, trigger a search to display results
      this.performSearch(query)
    }

    // focusedOptionIndex remains unchanged (no selection change)
  }

  handleArrowDown() {
    const isListboxDisplayed = this.resultsTarget.querySelector('.geo-search-results') !== null
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))

    // If the textbox is empty and the listbox is not displayed, opens the listbox and moves visual focus to the first option
    if (!isListboxDisplayed && this.inputTarget.value.trim() === "") {
      // Display all available locations
      this.displayAllLocations()
      // Move visual focus to first option
      this.focusedOptionIndex = 0
      // Update visual focus after a short delay to let the DOM update
      setTimeout(() => {
        const options = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
        this.updateVisualFocus(options)
      }, 0)
      return
    }

    // If no options available, do nothing
    if (allOptions.length === 0) return

    // Move visual focus to the next suggested value
    if (this.focusedOptionIndex === -1) {
      // No option selected yet, select the first one
      this.focusedOptionIndex = 0
    } else {
      // Move to next option
      this.focusedOptionIndex++
      if (this.focusedOptionIndex >= allOptions.length) {
        this.focusedOptionIndex = 0 // Loop back to first
      }
    }

    this.updateVisualFocus(allOptions)
  }

  handleArrowUp() {
    const isListboxDisplayed = this.resultsTarget.querySelector('.geo-search-results') !== null
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))

    // If the textbox is empty, first opens the listbox if it is not already displayed and then moves visual focus to the last option
    if (!isListboxDisplayed && this.inputTarget.value.trim() === "") {
      // Display all available locations
      this.displayAllLocations()
      // Move visual focus to last option
      setTimeout(() => {
        const options = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
        this.focusedOptionIndex = options.length - 1
        this.updateVisualFocus(options)
      }, 0)
      return
    }

    // If no options available, do nothing
    if (allOptions.length === 0) return

    // If the listbox is displayed and a suggestion is selected, moves visual focus to the previous suggested value
    if (this.focusedOptionIndex === -1) {
      // No option selected yet, select the last one
      this.focusedOptionIndex = allOptions.length - 1
    } else {
      // Move to previous option
      this.focusedOptionIndex--
      if (this.focusedOptionIndex < 0) {
        this.focusedOptionIndex = allOptions.length - 1 // Loop back to last
      }
    }

    this.updateVisualFocus(allOptions)
  }

  handleEnter() {
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))

    // If no option is focused, do nothing
    if (this.focusedOptionIndex === -1 || allOptions.length === 0) return

    // Get the focused option
    const focusedOption = allOptions[this.focusedOptionIndex]

    if (focusedOption) {
      // Trigger click on the focused option to select it
      focusedOption.click()
      // The selectResult method will handle setting the textbox value and closing the listbox
    }
  }

  handleEscape() {
    const isListboxDisplayed = this.resultsTarget.querySelector('.geo-search-results') !== null

    if (isListboxDisplayed) {
      // If the listbox is displayed, closes it
      this.clearResults()
    } else {
      // If the listbox is not displayed, clears the textbox
      this.clearSelection()
    }
  }

  handleArrowRight() {
    // Moves visual focus to the textbox (it's already there, DOM focus never left)
    // Reset visual focus on options
    this.focusedOptionIndex = -1
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
    allOptions.forEach(option => {
      option.classList.remove('geo-search-focused')
    })

    // The cursor movement is handled automatically by the browser since we don't preventDefault
  }

  handleArrowLeft() {
    // Moves visual focus to the textbox (it's already there, DOM focus never left)
    // Reset visual focus on options
    this.focusedOptionIndex = -1
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
    allOptions.forEach(option => {
      option.classList.remove('geo-search-focused')
    })

    // The cursor movement is handled automatically by the browser since we don't preventDefault
  }

  handleHome() {
    // Moves visual focus to the textbox (it's already there, DOM focus never left)
    // Reset visual focus on options
    this.focusedOptionIndex = -1
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
    allOptions.forEach(option => {
      option.classList.remove('geo-search-focused')
    })

    // The cursor movement to beginning is handled automatically by the browser since we don't preventDefault
  }

  handleEnd() {
    // Moves visual focus to the textbox (it's already there, DOM focus never left)
    // Reset visual focus on options
    this.focusedOptionIndex = -1
    const allOptions = Array.from(this.resultsTarget.querySelectorAll('.geo-search-result-item button'))
    allOptions.forEach(option => {
      option.classList.remove('geo-search-focused')
    })

    // The cursor movement to end is handled automatically by the browser since we don't preventDefault
  }

  displayAllLocations() {
    if (!this.allLocations) {
      this.displayError("Chargement des localisations en cours...")
      return
    }

    // Display all departments and regions
    this.resultsContainer = {
      departements: this.allLocations.departements,
      regions: this.allLocations.regions
    }
    this.renderAllResults()
  }

  updateVisualFocus(allOptions) {
    // Remove visual focus from all options
    allOptions.forEach((option, index) => {
      if (index === this.focusedOptionIndex) {
        option.classList.add('geo-search-focused')
        // Scroll into view if needed
        option.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
      } else {
        option.classList.remove('geo-search-focused')
      }
    })

    // DOM focus remains on the textbox (no option.focus() call)
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
          html += `<li class="geo-search-result-item" role="option">`
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

    // Reset visual focus when new results are displayed
    this.focusedOptionIndex = -1
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
    this.focusedOptionIndex = -1
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