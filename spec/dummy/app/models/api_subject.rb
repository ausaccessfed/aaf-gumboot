# frozen_string_literal: true

require 'accession'

class APISubject < ApplicationRecord
  include Accession::Principal

  has_many :api_subject_roles, dependent: :destroy
  has_many :roles, through: :api_subject_roles, dependent: :destroy

  valhammer
  validates :x509_cn, format: { with: /\A[\w-]+\z/ }

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to api_subject identity
    roles.joins(:permissions).pluck('permissions.value')
  end

  def functioning?
    # more than enabled? could inform functioning?
    # such as an administrative or AAF lock
    enabled?
  end
end
