# frozen_string_literal: true

class Subject < ApplicationRecord
  include Accession::Principal

  has_many :subject_roles, dependent: :destroy
  has_many :roles, through: :subject_roles, dependent: :destroy

  valhammer

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to subject identity
    roles.joins(:permissions).pluck('permissions.value')
  end

  def functioning?
    # more than enabled? could inform functioning?
    # such as an administrative or AAF lock
    enabled?
  end
end
