FactoryBot.define do
  factory :vocabulary do
    word { "MyString" }
    meaning { "MyText" }
    mastered { false }
    favorited { false }
    user { nil }
  end
end
