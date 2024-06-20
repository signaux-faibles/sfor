import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static values = {
        idToken: String,
        redirectUri: String,
        keycloakHost: String
    }
    connect() {
        const logoutUrl = new URL('/auth/realms/master/protocol/openid-connect/logout', this.keycloakHostValue)
        logoutUrl.searchParams.set('id_token_hint', this.idTokenValue)
        logoutUrl.searchParams.set('post_logout_redirect_uri', this.redirectUriValue)
        window.location.href = logoutUrl.toString()
    }
}
