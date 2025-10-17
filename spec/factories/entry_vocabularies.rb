FactoryBot.define do
  factory :entry_vocabulary do
    association :entry
    association :vocabulary
  end
end
