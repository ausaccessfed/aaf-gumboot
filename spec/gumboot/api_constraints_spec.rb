# frozen_string_literal: true

require 'spec_helper'

require 'gumboot/shared_examples/api_constraints'

require 'api_constraints'

RSpec.describe APIConstraints do
  let(:matching_request) do
    headers = { 'Accept' => 'application/vnd.aaf.example.v1+json' }
    instance_double(ActionDispatch::Request, headers: headers)
  end
  let(:non_matching_request) do
    headers = { 'Accept' => 'application/vnd.aaf.example.v2+json' }
    instance_double(ActionDispatch::Request, headers: headers)
  end

  include_examples 'API constraints'
end
