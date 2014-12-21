require 'spec_helper'

require 'gumboot/shared_examples/api_constraints'

require 'api_constraints'

RSpec.describe APIConstraints do
  let(:matching_request) do
    double(headers: { 'Accept' => 'application/vnd.aaf.example.v1+json' })
  end
  let(:non_matching_request) do
    double(headers: { 'Accept' => 'application/vnd.aaf.example.v2+json' })
  end

  include_examples 'API constraints'
end
