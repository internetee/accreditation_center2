require 'rails_helper'

RSpec.describe Test, type: :model do
  describe 'validations' do
    it 'validates presence of required fields' do
      test = build(:test, title_et: nil, title_en: nil, test_type: nil, time_limit_minutes: nil, passing_score_percentage: nil)

      expect(test.valid?).to be(false)
      expect(test.errors[:title_et]).to be_present
      expect(test.errors[:title_en]).to be_present
      expect(test.errors[:test_type]).to be_present
      expect(test.errors[:time_limit_minutes]).to be_present
      expect(test.errors[:passing_score_percentage]).to be_present
    end

    it 'validates time_limit_minutes is greater than 0' do
      test = build(:test, time_limit_minutes: 0)
      expect(test.valid?).to be(false)
      expect(test.errors[:time_limit_minutes]).to be_present

      test = build(:test, time_limit_minutes: -1)
      expect(test.valid?).to be(false)
      expect(test.errors[:time_limit_minutes]).to be_present

      test = build(:test, time_limit_minutes: 30)
      expect(test.valid?).to be(true)
    end

    it 'validates passing_score_percentage is between 0 and 100' do
      test = build(:test, passing_score_percentage: -1)
      expect(test.valid?).to be(false)
      expect(test.errors[:passing_score_percentage]).to be_present

      test = build(:test, passing_score_percentage: 101)
      expect(test.valid?).to be(false)
      expect(test.errors[:passing_score_percentage]).to be_present

      test = build(:test, passing_score_percentage: 50)
      expect(test.valid?).to be(true)
    end

    it 'validates practical tests must have 100% passing score' do
      test = build(:test, :practical, passing_score_percentage: 80)
      expect(test.valid?).to be(true)
    end
  end

  describe 'associations' do
    let(:test) { create(:test) }

    it 'has many test_categories_tests and test_categories through them' do
      category1 = create(:test_category)
      category2 = create(:test_category)

      test.test_categories << [category1, category2]

      expect(test.test_categories_tests.count).to eq(2)
      expect(test.test_categories).to include(category1, category2)
    end

    it 'has many test_attempts' do
      user = create(:user)
      attempt1 = create(:test_attempt, test: test, user: user)
      attempt2 = create(:test_attempt, test: test, user: user)

      expect(test.test_attempts).to include(attempt1, attempt2)
    end

    it 'has many questions through test_categories' do
      category = create(:test_category)
      question = create(:question, test_category: category)

      test.test_categories << category

      expect(test.questions).to include(question)
    end

    it 'has many practical_tasks' do
      task1 = create(:practical_task, test: test)
      task2 = create(:practical_task, test: test)

      expect(test.practical_tasks).to include(task1, task2)
    end
  end

  describe 'enums' do
    it 'defines test_type enum' do
      expect(Test.test_types).to eq({ 'theoretical' => 0, 'practical' => 1 })
    end

    it 'provides predicate methods for test types' do
      theoretical_test = create(:test, :theoretical)
      practical_test = create(:test, :practical)

      expect(theoretical_test.theoretical?).to be(true)
      expect(theoretical_test.practical?).to be(false)
      expect(practical_test.practical?).to be(true)
      expect(practical_test.theoretical?).to be(false)
    end
  end

  describe 'scopes' do
    it 'has active scope' do
      active_test = create(:test, active: true)
      inactive_test = create(:test, active: false)

      expect(Test.active).to include(active_test)
      expect(Test.active).not_to include(inactive_test)
    end

    it 'orders by created_at desc by default' do
      test1 = create(:test, created_at: 2.days.ago)
      test2 = create(:test, created_at: 1.day.ago)
      test3 = create(:test, created_at: Time.current)

      expect(Test.all).to eq([test3, test2, test1])
    end
  end

  describe 'callbacks' do
    it 'sets practical test passing score to 100% before save' do
      test = build(:test, :practical, passing_score_percentage: 80)
      test.save!

      expect(test.passing_score_percentage).to eq(100)
    end

    it 'generates random slug' do
      test = create(:test)
      expect(test.slug).to be_present
      expect(test.slug.length).to eq(8)
      expect(test.slug).to match(/\A[a-z0-9]+\z/)
    end
  end

  describe 'instance methods' do
    let(:test) { create(:test, :theoretical, time_limit_minutes: 60) }

    describe '#total_questions' do
      it 'returns sum of questions_per_category from test_categories' do
        category1 = create(:test_category, questions_per_category: 10)
        category2 = create(:test_category, questions_per_category: 15)

        test.test_categories << [category1, category2]

        expect(test.total_questions).to eq(25)
      end
    end

    describe '#estimated_duration' do
      it 'returns formatted duration string' do
        expect(test.estimated_duration).to eq("60 #{I18n.t('minutes')}")
      end
    end

    describe '#has_theoretical_questions?' do
      it 'returns true for theoretical tests' do
        theoretical_test = create(:test, :theoretical)
        expect(theoretical_test.has_theoretical_questions?).to be(true)
      end

      it 'returns false for practical tests' do
        practical_test = create(:test, :practical)
        expect(practical_test.has_theoretical_questions?).to be(false)
      end
    end

    describe '#has_practical_tasks?' do
      it 'returns true for practical tests' do
        practical_test = create(:test, :practical)
        expect(practical_test.has_practical_tasks?).to be(true)
      end

      it 'returns false for theoretical tests' do
        theoretical_test = create(:test, :theoretical)
        expect(theoretical_test.has_practical_tasks?).to be(false)
      end
    end

    describe '#theoretical_questions_count' do
      it 'returns questions count for theoretical tests' do
        category = create(:test_category)
        create(:question, test_category: category)
        create(:question, test_category: category)

        test.test_categories << category

        expect(test.theoretical_questions_count).to eq(2)
      end

      it 'returns nil for practical tests' do
        practical_test = create(:test, :practical)
        expect(practical_test.theoretical_questions_count).to be_nil
      end
    end

    describe '#practical_tasks_count' do
      it 'returns practical tasks count for practical tests' do
        practical_test = create(:test, :practical)
        create(:practical_task, test: practical_test)
        create(:practical_task, test: practical_test)

        expect(practical_test.practical_tasks_count).to eq(2)
      end

      it 'returns nil for theoretical tests' do
        theoretical_test = create(:test, :theoretical)
        expect(theoretical_test.practical_tasks_count).to be_nil
      end
    end

    describe '#total_components' do
      it 'returns theoretical questions count for theoretical tests' do
        category = create(:test_category)
        create(:question, test_category: category)
        create(:question, test_category: category)

        test.test_categories << category

        expect(test.total_components).to eq(2)
      end

      it 'returns practical tasks count for practical tests' do
        practical_test = create(:test, :practical)
        create(:practical_task, test: practical_test)
        create(:practical_task, test: practical_test)

        expect(practical_test.total_components).to eq(2)
      end

      it 'returns 0 for tests with no type' do
        test = build(:test, test_type: nil)
        expect(test.total_components).to eq(0)
      end
    end

    describe '#active_ordered_test_categories_with_join_id' do
      it 'returns only active categories ordered by join display_order and includes join id' do
        t = create(:test, :theoretical)
        c1 = create(:test_category, active: true)
        c2 = create(:test_category, active: true)
        c3 = create(:test_category, active: false)

        j2 = TestCategoriesTest.create!(test: t, test_category: c2, display_order: 1)
        j1 = TestCategoriesTest.create!(test: t, test_category: c1, display_order: 2)
        _j3 = TestCategoriesTest.create!(test: t, test_category: c3, display_order: 3)

        result = t.active_ordered_test_categories_with_join_id

        # only active categories
        expect(result.map(&:id)).to match_array([c2.id, c1.id])
        # ordered by join display_order (1 then 2)
        expect(result.map(&:id)).to eq([c2.id, c1.id])
        # each row includes the join id aliased as test_categories_test_id
        expect(result.first.attributes).to have_key('test_categories_test_id')
        expect(result.map { |r| r.attributes['test_categories_test_id'] }).to eq([j2.id, j1.id])
      end
    end
  end

  describe 'ransackable attributes and associations' do
    it 'defines ransackable attributes' do
      expect(Test.ransackable_attributes).to include('title_et', 'title_en', 'description_et', 'description_en', 'created_at')
    end

    it 'defines ransackable associations' do
      expect(Test.ransackable_associations).to include('questions', 'test_attempts', 'test_categories')
    end
  end

  describe 'friendly_id' do
    it 'generates unique slugs' do
      test1 = create(:test)
      test2 = create(:test)

      expect(test1.slug).not_to eq(test2.slug)
      expect(test1.slug).to be_present
      expect(test2.slug).to be_present
    end

    it 'allows finding by slug' do
      test = create(:test)
      found_test = Test.friendly.find(test.slug)

      expect(found_test).to eq(test)
    end
  end
end
