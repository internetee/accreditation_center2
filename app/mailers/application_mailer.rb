class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('email_from_address', 'noreply@internet.ee')
  layout 'mailer'
end
