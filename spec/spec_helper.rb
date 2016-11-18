require 'rubygems'
require 'factory_girl'
require 'rails/all'
require 'faker'
require 'rspec/rails'
require 'simplecov'

SimpleCov.start do
  add_filter('spec')
  add_filter('sample')
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/config/environment.rb', __FILE__)

load Rails.root.join('db/schema.rb')

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.include FactoryGirl::Syntax::Methods
end
