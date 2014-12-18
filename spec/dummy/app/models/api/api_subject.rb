require 'accession'

module API
  class APISubject < ActiveRecord::Base
    include Accession::Principal

    has_many :api_subject_roles
    has_many :roles, through: :api_subject_roles

    validates :x509_cn, presence: true
    validates :description, presence: true
    validates :mail, presence: true
    validates :enabled, inclusion: [true, false]

    def permissions
      # This could be extended to gather permissions from
      # other data sources providing input to api_subject identity
      roles.flat_map { |role| role.permissions.map(&:value) }
    end

    def functioning?
      # more then enabled could inform functioning?
      # such as an administrative or AAF lock
      enabled
    end
  end
end
