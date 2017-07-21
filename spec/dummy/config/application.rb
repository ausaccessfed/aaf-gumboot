# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

require 'valhammer'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
  end
end
