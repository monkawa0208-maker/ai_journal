FactoryBot.define do
  factory :entry do
    association :user
    title { Faker::Lorem.sentence(word_count: 5) }
    content { Faker::Lorem.paragraph(sentence_count: 10) }
    posted_on { Date.today }
    response { nil }
  end
end

