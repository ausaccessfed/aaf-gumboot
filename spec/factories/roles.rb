# frozen_string_literal: true
FactoryGirl.define do
  factory :role, class: 'Role' do
    name { Faker::Lorem.word }
  end
end
