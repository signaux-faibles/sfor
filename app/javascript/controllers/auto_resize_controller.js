import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["textarea"];

    connect() {
        this.resize(); // Adjust the textarea height on load if it has pre-filled content
    }

    resize() {
        this.element.style.height = "auto"; // Reset the height
        this.element.style.height = `${this.element.scrollHeight}px`; // Adjust height based on content
    }

    adjust() {
        this.resize(); // Adjust the height dynamically as the user types
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