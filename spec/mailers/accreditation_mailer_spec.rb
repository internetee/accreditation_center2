require 'rails_helper'

RSpec.describe AccreditationMailer, type: :mailer do
  it 'renders expiry email' do
    user = create(:user, email: 'u@example.com')
    mail = described_class.expiry_notice(user)
    expect(mail.to).to eq(['u@example.com'])
    expect(mail.subject).to be_present
    expect(mail.body.encoded).to include(user.username)
  end
end
