FactoryBot.define do
  factory :vocabulary do
    sequence(:word) { |n| "word#{n}" }
    meaning { "単語の意味" }
    mastered { false }
    favorited { false }
    association :user

    trait :mastered do
      mastered { true }
    end

    trait :favorited do
      favorited { true }
    end

    trait :with_entries do
      after(:create) do |vocabulary|
        create_list(:entry, 2, user: vocabulary.user, vocabularies: [vocabulary])
      end
    end
  end
end
