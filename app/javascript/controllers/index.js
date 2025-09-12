// Import and register all your controllers from the importmap under controllers/*

import { Application } from "@hotwired/stimulus"
import "tom-select"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

export { application }
