class MailLoggerInterceptor
  def self.delivering_email(message)
    Rails.logger.info("[Mail] To: #{Array(message.to).join(', ')} | Subject: #{message.subject}")

    if message.multipart?
      message.parts.each do |part|
        next unless part.content_type&.start_with?("text/plain", "text/html")

        Rails.logger.info("[Mail][#{part.content_type}] #{part.body.decoded}")
      end
    else
      Rails.logger.info("[Mail][#{message.mime_type}] #{message.body.decoded}")
    end
  end
end

ActionMailer::Base.register_interceptor(MailLoggerInterceptor) if Rails.env.development?
