require 'rails_helper'

RSpec.describe TestCategory, type: :model do
  describe 'validations' do
    it 'validates presence of names' do
      tc = described_class.new(name_et: nil, name_en: nil)
      expect(tc.valid?).to be(false)
      expect(tc.errors[:name_et]).to be_present
      expect(tc.errors[:name_en]).to be_present
    end

    it 'validates active inclusion' do
      tc = build(:test_category, active: nil)
      expect(tc.valid?).to be(false)
      expect(tc.errors[:active]).to be_present

      tc.active = true
      expect(tc.valid?).to be(true)
    end

    it 'validates domain_rule_url format if present' do
      tc = build(:test_category, domain_rule_url: 'not-a-url')
      expect(tc.valid?).to be(false)
      expect(tc.errors[:domain_rule_url]).to be_present

      tc.domain_rule_url = 'https://example.com/rule'
      expect(tc.valid?).to be(true)
    end
  end

  describe 'associations' do
    it 'has many tests through join and has many questions' do
      tc = create(:test_category)
      test = create(:test)
      tc.tests << test

      q1 = create(:question, test_category: tc, display_order: 2)
      q2 = create(:question, test_category: tc, display_order: 1)

      expect(tc.tests).to include(test)
      # questions default scope ordered by display_order
      expect(tc.questions).to eq([q2, q1])
    end

    it 'destroys dependent join records and questions' do
      tc = create(:test_category)
      test = create(:test)
      tc.tests << test
      create(:question, test_category: tc)

      expect { tc.destroy }.to change { TestCategoriesTest.count }.by(-1)
        .and change { Question.count }.by(-1)
    end
  end

  describe 'scopes' do
    it 'returns active categories' do
      active = create(:test_category, active: true)
      _inactive = create(:test_category, active: false)

      expect(TestCategory.active).to include(active)
      expect(TestCategory.active.pluck(:active)).to all(be(true))
    end
  end

  describe 'ransackable' do
    it 'exposes ransackable attributes' do
      attrs = TestCategory.ransackable_attributes
      expect(attrs).to include('name_et', 'name_en', 'description_et', 'description_en', 'domain_rule_reference', 'domain_rule_url', 'questions_per_category', 'active', 'created_at')
    end

    it 'exposes ransackable associations' do
      assocs = TestCategory.ransackable_associations
      expect(assocs).to include('questions', 'tests')
    end
  end

  describe '#name_with_rule' do
    it 'returns name when no rule present' do
      tc = build(:test_category, name_et: 'Kategooria X', name_en: 'Category X', domain_rule_reference: nil)
      I18n.with_locale(:en) do
        expect(tc.name_with_rule).to eq('Category X')
      end
    end

    it 'returns name appended with rule when present' do
      tc = build(:test_category, name_et: 'Kategooria X', name_en: 'Category X', domain_rule_reference: '10.1')
      I18n.with_locale(:en) do
        expect(tc.name_with_rule).to eq('Category X - 10.1')
      end
    end
  end
end
