import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    const savedTheme = localStorage.getItem("theme") || "system"
    this.setTheme({ currentTarget: { value: savedTheme } })
    this.opener = null

    if (this.hasModalTarget) {
      this.onDialogClose = this.onDialogClose.bind(this)
      this.modalTarget.addEventListener("close", this.onDialogClose)
    }
  }

  disconnect() {
    if (this.hasModalTarget) {
      this.modalTarget.removeEventListener("close", this.onDialogClose)
    }
  }

  open(event) {
    this.opener = event.currentTarget
    this.opener.setAttribute("aria-expanded", "true")

    if (!this.modalTarget.open) {
      this.modalTarget.showModal()
    }
  }

  close() {
    if (this.modalTarget.open) {
      this.modalTarget.close()
    }
  }

  onDialogClose() {
    const opener = this.opener
    this.opener = null
    if (!opener?.isConnected) return

    opener.setAttribute("aria-expanded", "false")

    // Wait until the dialog has fully closed and inert is lifted from the page.
    window.setTimeout(() => {
      opener.focus({ preventScroll: true })
    }, 0)
  }

  setTheme(event) {
    const theme = event.currentTarget.value
    localStorage.setItem("theme", theme)

    if (theme === "system") {
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
      document.documentElement.setAttribute("data-fr-theme", prefersDark ? "dark" : "light")

      window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
        document.documentElement.setAttribute("data-fr-theme", e.matches ? "dark" : "light")
      })
    } else {
      document.documentElement.setAttribute("data-fr-theme", theme)
    }
  }
}
