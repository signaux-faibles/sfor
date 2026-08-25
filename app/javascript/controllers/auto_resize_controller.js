import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["textarea"];

    connect() {
        // Only auto-size textareas. Applying height to comment cards breaks zoom (WCAG 1.4.4).
        if (this.element.matches("textarea")) {
            this.resize();
        }
    }

    resize() {
        if (!this.element.matches("textarea")) return;

        this.element.style.height = "auto";
        this.element.style.height = `${this.element.scrollHeight}px`;
    }

    adjust() {
        this.resize();
    }

    focus(event) {
        const turboFrameId = event.currentTarget.getAttribute("data-turbo-frame");
        const turboFrame = document.getElementById(turboFrameId);

        if (!turboFrame) {
            console.error("Turbo frame not found:", turboFrameId);
            return;
        }

        const observer = new MutationObserver((mutationsList, observer) => {
            for (const mutation of mutationsList) {
                if (mutation.type === "childList" && turboFrame.querySelector("form")) {
                    observer.disconnect();

                    const form = turboFrame.querySelector("form");
                    if (form) {
                        const textarea = form.querySelector("textarea");
                        if (textarea) {
                            textarea.focus();
                        }
                    }
                    break;
                }
            }
        });

        observer.observe(turboFrame, { childList: true, subtree: true });
    }
}
