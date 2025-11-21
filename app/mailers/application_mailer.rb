class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@signaux-faibles.local")
  layout "mailer"
end
