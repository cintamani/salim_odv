# config/initializers/gmail_api_delivery.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'base64'
require 'mail'

class GmailApiDelivery
  def deliver!(message)
    gmail_message = Google::Apis::GmailV1::Message.new(
      raw: message.to_s
    )

    gmail_service.send_user_message('me', gmail_message)
  end

  private

  def gmail_service
    @_gmail_service ||= begin
      service = Google::Apis::GmailV1::GmailService.new

      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_key.to_json),
        scope: 'https://www.googleapis.com/auth/gmail.send'
      )

      authorizer.sub = sender_email
      service.authorization = authorizer

      service
    end
  end

  def sender_email
    @_sender_email ||= Rails.application.credentials.gmail_api[:sender_email]
  end

  def service_account_key
    @_service_account_key ||= Rails.application.credentials.google_service_account
  end
end

ActionMailer::Base.add_delivery_method :gmail_api, GmailApiDelivery
