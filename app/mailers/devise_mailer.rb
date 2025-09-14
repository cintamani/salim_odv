# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default from: 'noreply@salimodv.org'
  default reply_to: 'info@salimodv.org'

  def confirmation_instructions(record, token, opts = {})
    opts[:subject] = 'Conferma il tuo account - Salim ODV'

    super
  end

  def reset_password_instructions(record, token, opts = {})
    opts[:subject] = 'Reset della password - Salim ODV'

    super
  end
end
