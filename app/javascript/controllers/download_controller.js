import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["button"];

    async disable(event) {
        event.preventDefault();

        // Store the parent element and original HTML
        const parent = this.buttonTarget.parentNode;
        const originalHTML = parent.innerHTML;

        parent.innerHTML = `<span class="disabled">Téléchargement en cours...</span>`;

        try {
            const response = await fetch(this.buttonTarget.getAttribute("href"));

            if (!response.ok) {
                throw new Error("Download failed");
            }

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = this.getFilenameFromResponse(response);
            document.body.appendChild(a);
            a.click();
            a.remove();
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error("Error during download:", error);
            alert("Une erreur est survenue pendant le téléchargement.");
        } finally {
            // Restore the original link HTML
            parent.innerHTML = originalHTML;

            // Re-attach the Stimulus controller
            this.connect();
        }
    }

    getFilenameFromResponse(response) {
        const contentDisposition = response.headers.get("content-disposition");
        const match = contentDisposition?.match(/filename="(.+)"/);
        return match ? match[1] : "download.xlsx";
    }
}