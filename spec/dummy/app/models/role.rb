# frozen_string_literal: true

class Role < ApplicationRecord
  has_many :api_subject_roles, dependent: :destroy
  has_many :api_subjects, through: :api_subject_roles, dependent: :destroy

  has_many :subject_roles, dependent: :destroy
  has_many :subjects, through: :subject_roles, dependent: :destroy

  has_many :permissions, dependent: :destroy

  valhammer
end
