import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  switch(event) {
    this.panelTargets.forEach(panel => {
      if (event.target.value === panel.dataset.panel) {
        panel.classList.remove('sf-segmented--hidden')
      } else {
        if (!panel.classList.contains('sf-segmented--hidden')) {
          panel.classList.add('sf-segmented--hidden')
        }
      }
    });
  }
}
