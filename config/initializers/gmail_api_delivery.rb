# config/initializers/gmail_api_delivery.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'base64'

class GmailApiDelivery
  def initialize(settings = {})
    @sender_email = Rails.application.credentials.gmail_api[:sender_email]
    @service_account_key = Rails.application.credentials.google_service_account
  end

  def deliver!(message)
    gmail_service = create_gmail_service
    gmail_message = create_gmail_message(message)
    gmail_service.send_user_message('me', gmail_message)
    Rails.logger.info "Email sent successfully via Gmail API to: #{message.to.join(', ')}"
  rescue => e
    Rails.logger.error "Failed to send email via Gmail API: #{e.message}"
    Rails.logger.error "Message details - To: #{message.to}, From: #{message.from}"
    raise e
  end

  private

  def create_gmail_service
    service = Google::Apis::GmailV1::GmailService.new

    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(@service_account_key.to_json),
      scope: ['https://www.googleapis.com/auth/gmail.send']
    )

    authorizer.sub = @sender_email
    service.authorization = authorizer
    service
  end

  def create_gmail_message(message)
    email_content = build_email_content(message)
    encoded_email = Base64.urlsafe_encode64(email_content).delete('=')
    Google::Apis::GmailV1::Message.new(raw: encoded_email)
  end

  def build_email_content(message)
    # Build proper RFC 2822 email format
    email_parts = []

    # Headers
    email_parts << "MIME-Version: 1.0"
    email_parts << "Date: #{Time.now.rfc2822}"
    email_parts << "Message-ID: <#{SecureRandom.uuid}@#{@sender_email.split('@').last}>"
    email_parts << "Subject: #{message.subject}"
    email_parts << "From: #{@sender_email}"
    email_parts << "To: #{message.to.join(', ')}"

    # Add Reply-To if different from sender
    if message.reply_to.present?
      email_parts << "Reply-To: #{message.reply_to.join(', ')}"
    end

    # Content headers
    if message.html_part.present?
      email_parts << "Content-Type: text/html; charset=UTF-8"
    else
      email_parts << "Content-Type: text/plain; charset=UTF-8"
    end
    email_parts << "Content-Transfer-Encoding: 7bit"

    # Empty line between headers and body
    email_parts << ""

    # Body
    if message.html_part.present?
      email_parts << message.html_part.body.to_s
    else
      email_parts << message.body.to_s
    end

    email_parts.join("\r\n")
  end
end

ActionMailer::Base.add_delivery_method :gmail_api, GmailApiDelivery
