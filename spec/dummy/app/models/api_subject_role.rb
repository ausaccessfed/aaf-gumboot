# frozen_string_literal: true

class APISubjectRole < ApplicationRecord
  belongs_to :api_subject
  belongs_to :role

  validates :api_subject, :role, presence: true
end
