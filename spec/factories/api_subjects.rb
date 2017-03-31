# frozen_string_literal: true

FactoryGirl.define do
  factory :api_subject, class: API::APISubject do
    x509_cn { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    contact_name { Faker::Name.name }
    contact_mail { Faker::Internet.email }
    enabled true

    trait :authorized do
      transient { permission '*' }

      after(:create) do |api_subject, attrs|
        role = create :role
        permission = create :permission, value: attrs.permission, role: role
        role.permissions << permission
        role.api_subjects << api_subject
      end
    end
  end
end
