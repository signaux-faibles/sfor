import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "button"]

  connect() {
    const savedTheme = localStorage.getItem('theme') || 'system'
    this.setTheme({ currentTarget: { value: savedTheme } })
    this.openedByButton = null

    if (this.hasModalTarget) {
      this.handleModalClose = this.handleModalClose.bind(this)
      this.modalTarget.addEventListener("close", this.handleModalClose)
    }
  }

  disconnect() {
    if (this.hasModalTarget) {
      this.modalTarget.removeEventListener("close", this.handleModalClose)
    }
  }

  open(event) {
    this.openedByButton = event.currentTarget
    const modal = this.modalTarget

    if (modal && this.openedByButton) {
      const openEvent = new CustomEvent('fr:modal:open', {
        bubbles: true,
        detail: { modal, button: this.openedByButton }
      })
      this.openedByButton.dispatchEvent(openEvent)
    }
  }

  close() {
    const modal = this.modalTarget

    if (modal && this.openedByButton) {
      const closeEvent = new CustomEvent('fr:modal:close', {
        bubbles: true,
        detail: { modal, button: this.openedByButton }
      })
      this.openedByButton.dispatchEvent(closeEvent)
    }

    this.restoreFocus()
  }

  handleModalClose() {
    this.restoreFocus()
  }

  restoreFocus() {
    const focusTarget = this.openedByButton?.closest("#header-menu")
      ? document.getElementById("header-menu-btn")
      : this.openedByButton

    requestAnimationFrame(() => focusTarget?.focus())
  }

  setTheme(event) {
    const theme = event.currentTarget.value
    localStorage.setItem('theme', theme)
    
    if (theme === 'system') {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      document.documentElement.setAttribute('data-fr-theme', prefersDark ? 'dark' : 'light')
      
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        document.documentElement.setAttribute('data-fr-theme', e.matches ? 'dark' : 'light')
      })
    } else {
      document.documentElement.setAttribute('data-fr-theme', theme)
    }
  }

  setThemeFromButton(event) {
    const theme = event.currentTarget.dataset.theme
    this.setTheme({ currentTarget: { value: theme } })
    this.close()
  }
} 