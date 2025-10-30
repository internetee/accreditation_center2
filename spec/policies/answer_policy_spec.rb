require 'rails_helper'

RSpec.describe AnswerPolicy, type: :policy do
  let(:record) { build(:answer) }

  context 'as regular user' do
    let(:user) { build(:user, role: :user, registrar_name: 'Registrar A') }
    subject(:policy) { described_class.new(user: user, record: record) }

    it 'permits index and show' do
      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
    end

    it 'forbids create, update, destroy' do
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end

  context 'as admin' do
    let(:user) { build(:user, role: :admin) }
    subject(:policy) { described_class.new(user: user, record: record) }

    it 'permits all management actions' do
      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end
end
