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
    this.allLocations = null
    this.loadAllLocations()

    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  async loadAllLocations() {
    try {
      const [departments, regions] = await Promise.all([
        fetch("https://geo.api.gouv.fr/departements?fields=nom,code&zone=metro,drom,com").then(r => r.json()),
        fetch("https://geo.api.gouv.fr/regions?fields=nom,code").then(r => r.json())
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

    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.clearResults()
    }
  }

  handleKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (event.altKey) {
        this.handleAltArrowDown()
      } else {
        this.handleArrowDown()
      }
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.handleArrowUp()
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.handleEnter()
    } else if (event.key === "Escape") {
      this.handleEscape()
    } else if (event.key === "Tab") {
      this.handleTab(event)
    } else if (["ArrowRight", "ArrowLeft", "Home", "End"].includes(event.key)) {
      this.clearActiveOption()
    }
  }

  getOptions() {
    return Array.from(this.resultsTarget.querySelectorAll('[role="option"]'))
  }

  handleAltArrowDown() {
    if (this.isListboxDisplayed()) return

    const query = this.inputTarget.value.trim()
    if (query === "") {
      this.displayAllLocations()
    } else {
      this.performSearch(query)
    }
  }

  handleArrowDown() {
    const options = this.getOptions()

    if (!this.isListboxDisplayed() && this.inputTarget.value.trim() === "") {
      this.displayAllLocations()
      this.focusedOptionIndex = 0
      setTimeout(() => this.updateVisualFocus(this.getOptions()), 0)
      return
    }

    if (options.length === 0) return

    if (this.focusedOptionIndex === -1) {
      this.focusedOptionIndex = 0
    } else {
      this.focusedOptionIndex = (this.focusedOptionIndex + 1) % options.length
    }

    this.updateVisualFocus(options)
  }

  handleArrowUp() {
    const options = this.getOptions()

    if (!this.isListboxDisplayed() && this.inputTarget.value.trim() === "") {
      this.displayAllLocations()
      setTimeout(() => {
        const renderedOptions = this.getOptions()
        this.focusedOptionIndex = renderedOptions.length - 1
        this.updateVisualFocus(renderedOptions)
      }, 0)
      return
    }

    if (options.length === 0) return

    if (this.focusedOptionIndex === -1) {
      this.focusedOptionIndex = options.length - 1
    } else {
      this.focusedOptionIndex = (this.focusedOptionIndex - 1 + options.length) % options.length
    }

    this.updateVisualFocus(options)
  }

  handleEnter() {
    const options = this.getOptions()
    if (this.focusedOptionIndex === -1 || options.length === 0) return

    options[this.focusedOptionIndex]?.click()
  }

  handleEscape() {
    if (this.isListboxDisplayed()) {
      this.clearResults()
    } else {
      this.clearSelection()
    }
  }

  handleTab() {
    if (this.isListboxDisplayed()) {
      this.clearResults()
    }
  }

  isListboxDisplayed() {
    return this.getOptions().length > 0
  }

  clearActiveOption() {
    this.focusedOptionIndex = -1
    this.getOptions().forEach(option => option.classList.remove("sf-geo-search-focused"))
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  setListboxOpen(isOpen) {
    this.inputTarget.setAttribute("aria-expanded", isOpen ? "true" : "false")
  }

  displayAllLocations() {
    if (!this.allLocations) {
      this.displayMessage("Chargement des localisations en cours...", "info")
      return
    }

    this.resultsContainer = {
      departements: this.allLocations.departements,
      regions: this.allLocations.regions
    }
    this.renderAllResults()
  }

  updateVisualFocus(options) {
    options.forEach((option, index) => {
      if (index === this.focusedOptionIndex) {
        option.classList.add("sf-geo-search-focused")
        option.scrollIntoView({ block: "nearest", behavior: "smooth" })
        if (option.id) {
          this.inputTarget.setAttribute("aria-activedescendant", option.id)
        }
      } else {
        option.classList.remove("sf-geo-search-focused")
      }
    })
  }

  search() {
    const query = this.inputTarget.value.trim()
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    if (query === "") {
      this.clearSelection()
      return
    }

    this.debounceTimeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceDelay)
  }

  async performSearch(query) {
    const isNumericOnly = /^\d+$/.test(query)

    try {
      if (isNumericOnly && query.length === 5) {
        await this.searchCommunesByPostalCode(query)
      } else if (isNumericOnly) {
        await this.searchDepartmentsByCode(query)
      } else {
        await Promise.all([
          this.searchCommunes(query),
          this.searchDepartments(query),
          this.searchRegions(query)
        ])
      }
    } catch (error) {
      console.error("Error performing geo search:", error)
      this.displayMessage("Une erreur est survenue lors de la recherche", "error")
    }
  }

  mapCommuneToResults(item) {
    const postalCodes = item.codesPostaux?.filter(Boolean) || []
    const nom = item.nom || ""

    if (postalCodes.length > 1) {
      return postalCodes.map(postalCode => ({
        type: "cp",
        code: postalCode,
        label: `${nom} (${postalCode})`,
        fullLabel: nom,
        postalCode,
        department: item.departement
      }))
    }

    const postalCode = postalCodes[0] || ""
    if (postalCode) {
      return [{
        type: "cp",
        code: postalCode,
        label: `${nom} (${postalCode})`,
        fullLabel: nom,
        postalCode,
        department: item.departement
      }]
    }

    return [{
      type: "insee",
      code: item.code || "",
      label: nom,
      fullLabel: nom,
      postalCode: "",
      department: item.departement
    }]
  }

  async searchCommunes(query) {
    try {
      const url = `https://geo.api.gouv.fr/communes?fields=code,codesPostaux,departement,nom&format=json&nom=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const data = await response.json()

      if (Array.isArray(data) && data.length > 0) {
        const results = data.flatMap(item => this.mapCommuneToResults(item))
        this.displayResults(results, "communes")
      }
    } catch (error) {
      console.error("Error searching communes:", error)
    }
  }

  async searchCommunesByPostalCode(postalCode) {
    try {
      const url = `https://geo.api.gouv.fr/communes?fields=code,codesPostaux,departement,nom&format=json&codePostal=${encodeURIComponent(postalCode)}`
      const response = await fetch(url)
      const data = await response.json()

      if (Array.isArray(data) && data.length > 0) {
        const results = data
          .flatMap(item => this.mapCommuneToResults(item))
          .filter(result => result.code === postalCode)
        this.displayResults(results, "communes")
      }
    } catch (error) {
      console.error("Error searching communes by postal code:", error)
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

    this.resultsContainer[category] = results
    this.renderAllResults()
  }

  renderAllResults() {
    if (!this.resultsTarget) return

    const categories = ["communes", "departements", "regions"]
    const categoryLabels = {
      communes: "Communes",
      departements: "Départements",
      regions: "Régions"
    }

    let optionIndex = 0
    let html = '<ul class="sf-geo-search-results fr-list" role="presentation">'

    categories.forEach(category => {
      const categoryResults = this.resultsContainer?.[category]
      if (!categoryResults?.length) return

      html += `<li class="sf-geo-search-category-label" role="presentation" aria-hidden="true">${categoryLabels[category] || category}</li>`

      categoryResults.forEach(result => {
        const optionId = `${this.resultsTarget.id}-option-${optionIndex}`
        optionIndex += 1
        html += `<li id="${optionId}" class="sf-geo-search-result-item" role="option" tabindex="-1"`
        html += ` data-action="click->geo-search#selectResult"`
        html += ` data-result-type="${result.type}"`
        html += ` data-result-code="${result.code}"`
        html += ` data-result-label="${this.escapeHtml(result.label)}"`
        html += ` data-result-full-label="${this.escapeHtml(result.fullLabel)}">`
        html += `${this.escapeHtml(result.label)}`
        html += `</li>`
      })
    })

    html += "</ul>"

    if (optionIndex === 0) {
      this.displayMessage("Aucun résultat trouvé.", "info")
      return
    }

    this.resultsTarget.innerHTML = html
    this.setListboxOpen(true)
    this.focusedOptionIndex = -1
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  selectResult(event) {
    const option = event.currentTarget
    const type = option.dataset.resultType
    const code = option.dataset.resultCode
    const label = option.dataset.resultLabel
    const fullLabel = option.dataset.resultFullLabel

    if (this.hasHiddenTypeTarget) {
      this.hiddenTypeTarget.value = type
    }
    if (this.hasHiddenCodeTarget) {
      this.hiddenCodeTarget.value = code
    }
    if (this.hasHiddenLabelTarget) {
      this.hiddenLabelTarget.value = fullLabel
    }

    this.inputTarget.value = label
    this.clearResults()
    this.selectedResult = { type, code, label: fullLabel }
    this.inputTarget.focus()
  }

  clearResults() {
    if (this.resultsTarget) {
      this.resultsTarget.innerHTML = ""
    }
    this.resultsContainer = {}
    this.focusedOptionIndex = -1
    this.setListboxOpen(false)
    this.inputTarget.removeAttribute("aria-activedescendant")
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

  displayMessage(message, type) {
    if (!this.resultsTarget) return

    const alertClass = type === "error" ? "fr-alert--error" : "fr-alert--info"
    this.resultsTarget.innerHTML = `<div class="fr-alert ${alertClass} fr-mt-2w" role="status"><p>${message}</p></div>`
    this.setListboxOpen(true)
    this.focusedOptionIndex = -1
    this.inputTarget.removeAttribute("aria-activedescendant")
  }
}
