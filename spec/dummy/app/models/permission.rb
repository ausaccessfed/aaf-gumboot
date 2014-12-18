class Permission < ActiveRecord::Base
  belongs_to :role
  validates :value, presence: true
  validates :role, presence: true
end
