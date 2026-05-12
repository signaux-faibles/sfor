import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenValues", "tags"]
  static values = {
    debounce: Number,
    options: Array,
    required: Boolean,
    label: String
  }

  connect() {
    this.debounceTimeout = null
    this.debounceDelay = this.hasDebounceValue ? this.debounceValue : 300
    this.selectedItems = []
    this.focusedOptionIndex = -1
    this.allOptions = this.hasOptionsValue ? this.optionsValue : []

    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)

    const wrap = this.inputTarget.closest('.sf-multiselect-input-wrap')
    this.resizeObserver = new ResizeObserver(() => this.truncateTags())
    this.resizeObserver.observe(wrap)

    this.restoreFromHiddenField()

    if (this.hasRequiredValue && this.requiredValue) {
      this.addRequiredMarker()
      this.updateRequiredValidity()
    }
  }

  disconnect() {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout)
    document.removeEventListener('click', this.handleClickOutside)
    this.resizeObserver?.disconnect()
  }

  restoreFromHiddenField() {
    const raw = this.hiddenValuesTarget.value
    if (!raw) return
    try {
      this.selectedItems = JSON.parse(raw)
      this.renderTags()
    } catch {
      this.selectedItems = []
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.clearResults()
    }
  }

  handleKeydown(event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      if (event.altKey) {
        this.openIfClosed()
      } else {
        this.handleArrowDown()
      }
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      if (event.altKey) {
        this.closeAndFocusInput()
      } else {
        this.handleArrowUp()
      }
    } else if (event.key === 'Enter') {
      event.preventDefault()
      this.handleEnter()
    } else if (event.key === 'Escape') {
      const isOpen = this.resultsTarget.querySelector('.sf-multiselect-results') !== null
      if (isOpen) {
        this.clearResults()
      } else {
        this.inputTarget.value = ''
        this.selectedItems = []
        this.updateHiddenField()
        this.renderTags()
      }
    } else if (event.key === 'Tab') {
      this.clearResults()
    } else if (event.key === 'Backspace' && this.inputTarget.value === '' && this.selectedItems.length > 0) {
      this.selectedItems.shift()
      this.updateHiddenField()
      this.renderTags()
    } else if (['ArrowRight', 'ArrowLeft', 'Home', 'End'].includes(event.key)) {
      this.focusedOptionIndex = -1
      this.clearOptionFocus()
    } else if (event.key.length === 1 && !event.ctrlKey && !event.metaKey) {
      this.focusedOptionIndex = -1
      this.clearOptionFocus()
    }
  }

  openIfClosed() {
    const isOpen = this.resultsTarget.querySelector('.sf-multiselect-results') !== null
    if (isOpen) return
    this.performSearch(this.inputTarget.value.trim())
  }

  closeAndFocusInput() {
    const isOpen = this.resultsTarget.querySelector('.sf-multiselect-results') !== null
    if (!isOpen) return
    this.clearResults()
    this.inputTarget.focus()
  }

  handleArrowDown() {
    const isOpen = this.resultsTarget.querySelector('.sf-multiselect-results') !== null
    const options = this.getOptionButtons()

    if (!isOpen) {
      this.performSearch(this.inputTarget.value.trim())
      this.focusedOptionIndex = 0
      setTimeout(() => this.updateVisualFocus(this.getOptionButtons()), 0)
      return
    }

    if (options.length === 0) return
    this.focusedOptionIndex = this.focusedOptionIndex === -1
      ? 0
      : (this.focusedOptionIndex + 1) % options.length
    this.updateVisualFocus(options)
  }

  handleArrowUp() {
    const isOpen = this.resultsTarget.querySelector('.sf-multiselect-results') !== null

    if (!isOpen) {
      this.performSearch(this.inputTarget.value.trim())
      setTimeout(() => {
        const opts = this.getOptionButtons()
        this.focusedOptionIndex = opts.length - 1
        this.updateVisualFocus(opts)
      }, 0)
      return
    }

    const options = this.getOptionButtons()
    if (options.length === 0) return
    this.focusedOptionIndex = this.focusedOptionIndex === -1
      ? options.length - 1
      : (this.focusedOptionIndex - 1 + options.length) % options.length
    this.updateVisualFocus(options)
  }

  handleEnter() {
    const options = this.getOptionButtons()
    if (this.focusedOptionIndex !== -1 && options.length > 0) {
      options[this.focusedOptionIndex]?.click()
    } else {
      this.clearResults()
    }
  }

  getOptionButtons() {
    return Array.from(this.resultsTarget.querySelectorAll('.sf-multiselect-result-item button'))
  }

  updateVisualFocus(options) {
    options.forEach((option, index) => {
      option.classList.toggle('sf-multiselect-focused', index === this.focusedOptionIndex)
      if (index === this.focusedOptionIndex) {
        option.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
        const li = option.closest('[role="option"]')
        if (li) this.inputTarget.setAttribute('aria-activedescendant', li.id)
      }
    })
  }

  clearOptionFocus() {
    this.getOptionButtons().forEach(btn => btn.classList.remove('sf-multiselect-focused'))
    this.inputTarget.removeAttribute('aria-activedescendant')
  }

  search() {
    const query = this.inputTarget.value.trim()
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout)
    if (query === "") {
      this.clearResults()
      return
    }
    this.debounceTimeout = setTimeout(() => this.performSearch(query), this.debounceDelay)
  }

  performSearch(query) {
    if (this.allOptions.length === 0) return

    const q = query.toLowerCase()
    const filtered = q === ""
      ? this.allOptions
      : this.allOptions.filter(opt => opt.label.toLowerCase().includes(q))

    const withSelection = filtered.map(opt => ({
      ...opt,
      selected: this.selectedItems.some(sel => sel.value === opt.value)
    }))

    // Selected items first, then the rest
    const sorted = [
      ...withSelection.filter(opt => opt.selected),
      ...withSelection.filter(opt => !opt.selected)
    ]

    this.renderResults(sorted)
  }

  renderResults(options) {
    if (!this.resultsTarget) return

    if (options.length === 0) {
      this.resultsTarget.innerHTML = '<div class="fr-alert fr-alert--info fr-mt-2w"><p>Aucun résultat trouvé.</p></div>'
      return
    }

    const listboxLabel = this.hasLabelValue ? ` aria-label="${this.escapeHtml(this.labelValue)}"` : ''
    let html = `<ul class="sf-multiselect-results fr-list" role="listbox"${listboxLabel}>`
    options.forEach((opt, index) => {
      const selectedClass = opt.selected ? ' sf-multiselect-result-item--selected' : ''
      const iconClass = opt.selected ? ' fr-icon-success-fill' : ''
      const optionId = `${this.resultsTarget.id}-option-${index}`
      html += `<li id="${optionId}" class="sf-multiselect-result-item${selectedClass}" role="option" aria-selected="${opt.selected}">`
      html += `<button type="button" class="fr-btn fr-btn--tertiary-no-outline fr-btn--sm fr-btn--icon-left${iconClass}" `
      html += `data-action="click->multiselect#toggleResult" `
      html += `data-result-value="${this.escapeHtml(String(opt.value))}" `
      html += `data-result-label="${this.escapeHtml(opt.label)}">`
      html += this.escapeHtml(opt.label)
      html += `</button>`
      html += `</li>`
    })
    html += '</ul>'

    this.resultsTarget.innerHTML = html
    this.focusedOptionIndex = -1
    this.inputTarget.setAttribute('aria-expanded', 'true')
  }

  toggleResult(event) {
    const value = event.currentTarget.dataset.resultValue
    const label = event.currentTarget.dataset.resultLabel
    const existingIndex = this.selectedItems.findIndex(item => item.value === value)
    if (existingIndex !== -1) {
      this.selectedItems.splice(existingIndex, 1)
    } else {
      this.selectedItems.push({ value, label })
    }

    this.updateHiddenField()
    this.renderTags()
    this.inputTarget.value = ""
    this.clearResults()
    this.inputTarget.focus()
  }

  removeItem(event) {
    event.stopPropagation()
    const value = event.currentTarget.dataset.itemValue
    this.selectedItems = this.selectedItems.filter(item => item.value !== value)
    this.updateHiddenField()
    this.renderTags()
  }

  updateHiddenField() {
    this.hiddenValuesTarget.value = JSON.stringify(this.selectedItems)
    if (this.hasRequiredValue && this.requiredValue) {
      this.updateRequiredValidity()
    }
  }

  addRequiredMarker() {
    const label = this.element.querySelector('.fr-label')
    if (label) {
      const asterisk = document.createElement('span')
      asterisk.setAttribute('aria-hidden', 'true')
      asterisk.textContent = ' *'
      label.appendChild(asterisk)
    }
    this.inputTarget.setAttribute('aria-required', 'true')
  }

  updateRequiredValidity() {
    if (this.selectedItems.length === 0) {
      this.inputTarget.setAttribute('required', '')
      this.inputTarget.setCustomValidity("Veuillez sélectionner au moins un élément.")
    } else {
      this.inputTarget.removeAttribute('required')
      this.inputTarget.setCustomValidity("")
    }
  }

  renderTags() {
    if (!this.hasTagsTarget) return

    this.updateInputVisibility()

    if (this.selectedItems.length === 0) {
      this.tagsTarget.innerHTML = ""
      return
    }

    let html = '<ul class="sf-multiselect-tags">'
    this.selectedItems.forEach(item => {
      html += `<li class="sf-multiselect-tag">`
      html += `<span>${this.escapeHtml(item.label)}</span>`
      html += `<button type="button" class="fr-btn fr-btn--tertiary-no-outline fr-btn--sm fr-icon-close-line" `
      html += `data-action="click->multiselect#removeItem" `
      html += `data-item-value="${this.escapeHtml(String(item.value))}" `
      html += `aria-label="Retirer ${this.escapeHtml(item.label)}">`
      html += `</button>`
      html += `</li>`
    })
    html += '</ul>'

    this.tagsTarget.innerHTML = html
    this.truncateTags()
  }

  updateInputVisibility() {
    const wrap = this.inputTarget.closest('.sf-multiselect-input-wrap')
    if (wrap) wrap.classList.toggle('sf-multiselect--has-values', this.selectedItems.length > 0)
  }

  focusInput() {
    this.inputTarget.focus()
  }

  truncateTags() {
    const tagsList = this.tagsTarget.querySelector('.sf-multiselect-tags')
    if (!tagsList) return

    const tagItems = Array.from(tagsList.querySelectorAll('.sf-multiselect-tag:not(.sf-multiselect-tag-overflow)'))
    if (tagItems.length === 0) return

    // Reset
    tagItems.forEach(tag => {
      tag.classList.remove('sf-multiselect-tag--hidden')
      tag.style.maxWidth = ''
    })
    tagsList.querySelector('.sf-multiselect-tag-overflow')?.remove()

    // Tag unique : la CSS gère la troncature via text-overflow + max-width: 100%
    if (tagItems.length === 1) return

    // Plusieurs tags : on n'affiche que le premier + badge "+N"
    tagItems.slice(1).forEach(tag => tag.classList.add('sf-multiselect-tag--hidden'))

    const badge = document.createElement('li')
    badge.className = 'sf-multiselect-tag sf-multiselect-tag-overflow'
    badge.setAttribute('aria-hidden', 'true')
    badge.textContent = `+${tagItems.length - 1}`
    tagsList.appendChild(badge)

    // Tronquer le premier tag si lui + le badge dépassent la largeur disponible
    const wrap = this.inputTarget.closest('.sf-multiselect-input-wrap')
    const wrapRect = wrap.getBoundingClientRect()
    const paddingRight = parseFloat(getComputedStyle(wrap).paddingRight)
    const gap = 4
    const limit = wrapRect.right - paddingRight
    const badgeWidth = badge.getBoundingClientRect().width + gap

    const tagLeft = tagItems[0].getBoundingClientRect().left
    if (tagItems[0].getBoundingClientRect().right > limit - badgeWidth) {
      tagItems[0].style.maxWidth = `${Math.max(limit - badgeWidth - tagLeft, 32)}px`
    }
  }

  clearResults() {
    if (this.resultsTarget) this.resultsTarget.innerHTML = ""
    this.focusedOptionIndex = -1
    this.inputTarget.setAttribute('aria-expanded', 'false')
    this.inputTarget.removeAttribute('aria-activedescendant')
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
