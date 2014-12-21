require 'spec_helper'

require 'gumboot/shared_examples/api_constraints'

require 'api_constraints'

RSpec.describe APIConstraints do
  let(:matching_request) { double }
  let(:non_matching_request) { double }
  let(:matching_header) { 'application/vnd.aaf.example.v1+json' }
  let(:non_matching_header) { 'application/vnd.aaf.example.v2+json' }

  include_examples 'API constraints'
end
