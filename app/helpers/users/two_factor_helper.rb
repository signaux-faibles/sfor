require "rqrcode"

module Users::TwoFactorHelper
  ISSUER = "Signaux Faibles".freeze

  def two_factor_qr_svg(user)
    uri = user.otp_provisioning_uri(user.email, issuer: ISSUER)
    svg = RQRCode::QRCode.new(uri).as_svg(
      color: "000",
      fill: "fff",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true,
      viewbox: true
    )
    svg.sub(/\A<\?xml[^>]*\?>\s*/m, "")
  end

  def two_factor_manual_secret(user)
    user.otp_secret.to_s.chars.each_slice(4).map(&:join).join(" ")
  end
end
