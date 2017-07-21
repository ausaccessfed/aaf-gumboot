# frozen_string_literal: true

class Permission < ApplicationRecord
  belongs_to :role

  valhammer

  validates :value, format: Accession::Permission.regexp
end
