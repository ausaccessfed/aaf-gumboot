FactoryGirl.define do
  factory :api_subject, class: API::APISubject do
    x509_dn { "cn=#{Faker::Internet.domain_name},o='#{Faker::Company.name}'" }

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
