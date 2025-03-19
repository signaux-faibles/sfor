import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "button"]

  connect() {
    const savedTheme = localStorage.getItem('theme') || 'system'
    this.setTheme({ currentTarget: { value: savedTheme } })
  }

  open(event) {
    console.log("Opening modal")
    const modal = this.modalTarget
    const button = this.buttonTarget
    
    if (modal && button) {
      const openEvent = new CustomEvent('fr:modal:open', {
        bubbles: true,
        detail: { modal, button }
      })
      button.dispatchEvent(openEvent)
    }
  }

  close(event) {
    const modal = this.modalTarget
    const button = this.buttonTarget
    
    if (modal && button) {
      const closeEvent = new CustomEvent('fr:modal:close', {
        bubbles: true,
        detail: { modal, button }
      })
      button.dispatchEvent(closeEvent)
    }
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