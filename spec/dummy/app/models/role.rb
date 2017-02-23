# frozen_string_literal: true
class Role < ActiveRecord::Base
  has_many :api_subject_roles
  has_many :api_subjects, through: :api_subject_roles

  has_many :subject_roles
  has_many :subjects, through: :subject_roles

  has_many :permissions

  valhammer
end
