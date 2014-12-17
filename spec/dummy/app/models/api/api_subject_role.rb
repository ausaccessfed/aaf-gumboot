module API
  class APISubjectRole < ActiveRecord::Base
    belongs_to :api_subject, class_name: 'API::APISubject'
    belongs_to :role, class_name: 'Role'

    validates :api_subject, :role, presence: true
  end
end
