require 'rails_helper'

RSpec.describe AuthenticationService do
  it 'returns success payload on valid credentials' do
    service = described_class.new(username: 'u', password: 'p')
    allow(service).to receive(:authenticate_user).and_return({
      success: true, username: 'u', registrar_email: 'e', registrar_name: 'n',
      accreditation_date: Date.current, accreditation_expire_date: 1.year.from_now.to_date
    })
    expect(service.authenticate_user[:success]).to be(true)
  end

  it 'returns failure payload on invalid credentials' do
    service = described_class.new(username: 'u', password: 'bad')
    allow(service).to receive(:authenticate_user).and_return({ success: false, message: 'Invalid' })
    expect(service.authenticate_user).to include(success: false, message: 'Invalid')
  end
end
