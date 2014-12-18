FactoryGirl.define do
  factory :role, class: 'Role' do
    name { Faker::Lorem.word }
  end
end
