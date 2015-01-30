class Permission < ActiveRecord::Base
  belongs_to :role
  validates :value, presence: true, uniqueness: { scope: :role },
                    format: Accession::Permission.regexp
  validates :role, presence: true
end
