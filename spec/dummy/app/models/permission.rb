# frozen_string_literal: true
class Permission < ActiveRecord::Base
  belongs_to :role

  valhammer

  validates :value, format: Accession::Permission.regexp
end
