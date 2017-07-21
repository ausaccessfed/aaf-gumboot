# frozen_string_literal: true

class SubjectRole < ApplicationRecord
  belongs_to :subject
  belongs_to :role

  validates :subject, :role, presence: true
end
