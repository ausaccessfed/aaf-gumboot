class Subject < ActiveRecord::Base
  include Accession::Principal

  has_many :subject_roles
  has_many :roles, through: :subject_roles

  validates :name, :mail, presence: true
  validates :targeted_id, :shared_token, presence: true, if: :complete?
  validates :enabled, :complete, inclusion: [true, false]

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to subject identity
    subject_role_assignments.flat_map { |ra| ra.role.permissions.map(&:value) }
  end

  def functioning?
    # more then enabled could inform functioning?
    # such as an administrative or AAF lock
    enabled
  end
end
