require 'spec_helper'

require 'gumboot/shared_examples/foreign_keys'

RSpec.describe 'Foreign Keys' do
  include_examples 'Foreign Keys', 'permissions', 'roles', 'role_id'
  include_examples(
    'Foreign Keys',
    'api_subject_roles',
    'api_subjects',
    'api_subject_id'
  )
  include_examples 'Foreign Keys', 'api_subject_roles', 'roles', 'role_id'
  include_examples 'Foreign Keys', 'subject_roles', 'subjects', 'subject_id'
  include_examples 'Foreign Keys', 'subject_roles', 'roles', 'role_id'
end
