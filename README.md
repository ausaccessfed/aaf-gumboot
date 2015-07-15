# AAF Gumboot

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]
[![Dependency Status][DS img]][Dependency Status]
[![Code Climate][CC img]][Code Climate]
[![Coverage Status][CS img]][Code Climate]

[Gem Version]: https://rubygems.org/gems/aaf-gumboot
[Build Status]: https://codeship.com/projects/91207
[Dependency Status]: https://gemnasium.com/ausaccessfed/aaf-gumboot
[Code Climate]: https://codeclimate.com/github/ausaccessfed/aaf-gumboot

[GV img]: https://img.shields.io/gem/v/aaf-gumboot.svg
[BS img]: https://img.shields.io/codeship/9f557e20-0ccb-0133-b925-7aae0ba3591b/develop.svg
[DS img]: https://img.shields.io/gemnasium/ausaccessfed/aaf-gumboot/develop.svg
[CC img]: https://img.shields.io/codeclimate/github/ausaccessfed/aaf-gumboot.svg
[CS img]: https://img.shields.io/codeclimate/coverage/github/ausaccessfed/aaf-gumboot.svg

Subjects, APISubjects, Roles, Permissions, Access Control, RESTful APIs, Events and the endless stream of possible Gems.

Gumboot sloshes through these **muddy** topics for AAF applications, bringing down swift justice where it finds problems.

![](http://i.imgur.com/XP4Yw6e.jpg)

```
Copyright 2014-2015, Australian Access Federation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Gems

The way we build ruby applications has tried to be standardised as much as possible at a base layer. You're likely going to want all these Gems in your Gemfile for a Rails app or a considerable subset of them for a non Rails app.

```ruby
gem 'rails', '4.1.8' # Ensure latest release
gem 'mysql2'

gem 'aaf-lipstick'
gem 'accession'
gem 'thumper'

gem 'unicorn', require: false

group :development, :test do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'shoulda-matchers'

  gem 'factory_girl_rails'
  gem 'faker'

  gem 'rubocop', require: false
  gem 'simplecov', require: false
  gem 'coveralls'

  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-rspec', require: false
  gem 'guard-brakeman', require: false

  gem 'aaf-gumboot'
end
```

And then execute:

    $ bundle

## Acronyms
Before getting started it is **strongly recommended** that you ensure 'API' is an acronym within your application

e.g for Rails applications in config/initializers/inflections.rb

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end
```

### Models
All AAF applications **must** provide the following models.

Example implementations are provided for ActiveModel and Sequel below. Developers may extend models or implement them in any way they wish.

For each model a FactoryGirl factory *must also be provided*.

For each model the provided RSpec shared examples **must** be used within your application and **must** pass.

#### Subject
A Subject represents state and security operations for a single application user.

##### Active Model
```ruby
class Subject < ActiveRecord::Base
  include Accession::Principal

  has_many :subject_roles
  has_many :roles, through: :subject_roles

  validates :name, :mail, presence: true
  validates :targeted_id, :shared_token, presence: true, if: :complete?
  validates :enabled, :complete, inclusion: [true, false]

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to subject identity
    roles.flat_map { |role| role.permissions.map(&:value) }
  end

  def functioning?
    # more than enabled? could inform functioning?
    # such as an administrative or AAF lock
    enabled?
  end
end
```
##### Sequel
``` ruby
class Subject < Sequel::Model
  include Accession::Principal

  many_to_many :roles, class: 'Role'

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to api_subject identity
    roles.flat_map { |role| role.permissions.map(&:value) }
  end

  def functioning?
    # more than enabled? could inform functioning?
    # such as an administrative or AAF lock
    enabled?
  end

  def validate
    validates_presence [:name, :mail, :enabled, :complete]
    validates_presence [:targeted_id, :shared_token] if complete?
  end
end
```

##### RSpec shared examples
```ruby
require 'spec_helper'

require 'gumboot/shared_examples/subjects'

RSpec.describe Subject, type: :model do
  include_examples 'Subjects'

  # TODO: examples for your model extensions here
end
```

#### API Subject
An API Subject is an extension of the Subject concept reserved specifically for Subjects that utilise x509 client certificate verification to make requests to the applications RESTful API endpoints.

Having this model live within the API module is recommended.

##### Active Model
``` ruby
module API
  class APISubject < ActiveRecord::Base
    include Accession::Principal

    has_many :api_subject_roles
    has_many :roles, through: :api_subject_roles

    validates :x509_cn, presence: true
    validates :contact_name, :contact_mail, :description, presence: true
    validates :enabled, inclusion: [true, false]

    def permissions
      # This could be extended to gather permissions from
      # other data sources providing input to api_subject identity
      roles.flat_map { |role| role.permissions.map(&:value) }
    end

    def functioning?
      # more than enabled? could inform functioning?
      # such as an administrative or AAF lock
      enabled?
    end
  end
end

```

##### Sequel
``` ruby
module API
  class APISubject < Sequel::Model
    include Accession::Principal

    many_to_many :roles, class: 'Role'

    def permissions
      # This could be extended to gather permissions from
      # other data sources providing input to api_subject identity
      roles.flat_map { |role| role.permissions.map(&:value) }
    end

    def functioning?
      # more than enabled? could inform functioning?
      # such as an administrative or AAF lock
      enabled?
    end

    def validate
      validates_presence [:x509_cn, :description,
                          :contact_name, :contact_mail, :enabled]
    end
  end
end
```

##### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_subjects'

RSpec.describe API::APISubject, type: :model do
  include_examples 'API Subjects'

  # TODO: examples for your model extensions here
end
```

#### Role
The term *Role* is thrown around a lot and it's meaning is very diluted. For our purposes a Role is really a collection of permissions and a collection of Subjects for whom each associated permission is applied.

##### Active Record
``` ruby
class Role < ActiveRecord::Base
  has_many :api_subject_roles, class_name: 'API::APISubjectRole'
  has_many :api_subjects, through: :api_subject_roles

  has_many :subject_roles
  has_many :subjects, through: :subject_roles

  has_many :permissions

  validates :name, presence: true
end
```

##### Sequel
``` ruby
class Role < Sequel::Model
  one_to_many :permissions

  many_to_many :api_subjects, class: 'API::APISubject'
  many_to_many :subjects

  def validate
    super
    validates_presence [:name]
  end
end
```

##### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/roles'

RSpec.describe Role, type: :model do
  include_examples 'Roles'

  # TODO: examples for your model extensions here
end
```

#### Permission
Permissions are the lowest level constructs in security policies. They describe which actions a Subject is able to perform or data the Subject is able to access.

##### Active Record
``` ruby
class Permission < ActiveRecord::Base
  belongs_to :role
  validates :value, presence: true, uniqueness: { scope: :role },
                    format: Accession::Permission.regexp
  validates :role, presence: true
end
```

##### Sequel
``` ruby
class Permission < Sequel::Model
  many_to_one :role

  def validate
    super
    validates_presence [:role, :value]
  end
end
```

##### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/permissions'

RSpec.describe Permission, type: :model do
  include_examples 'Permissions'

  # TODO: examples for your model extensions here
end
```

### Access Control
TODO

### Controllers

AAF applications must utilise controllers which default to verifying authentication and access control on every request. This can be changed as implementations require to be publicly accessible for example but must be explicitly configured in code to make it clear to all.

###### Rails 4.x
See `spec/dummy/app/controllers/application_controller.rb` for the implementation this example is based on

``` ruby
class ApplicationController < ActionController::Base
  Forbidden = Class.new(StandardError)
  private_constant :Forbidden
  rescue_from Forbidden, with: :forbidden

  Unauthorized = Class.new(StandardError)
  private_constant :Unauthorized
  rescue_from Unauthorized, with: :unauthorized

  protect_from_forgery with: :exception
  before_action :ensure_authenticated
  after_action :ensure_access_checked

  def subject
    subject = session[:subject_id] && Subject.find_by_id(session[:subject_id])
    return nil unless subject.try(:functioning?)
    @subject = subject
  end

  protected

  def ensure_authenticated
    return redirect_to('/auth/login') unless session[:subject_id]

    @subject = Subject.find_by(id: session[:subject_id])
    fail(Unauthorized, 'Subject invalid') unless @subject
    fail(Unauthorized, 'Subject not functional') unless @subject.functioning?
  end

  def ensure_access_checked
    return if @access_checked

    method = "#{self.class.name}##{params[:action]}"
    fail("No access control performed by #{method}")
  end

  def check_access!(action)
    fail(Forbidden) unless subject.permits?(action)
    @access_checked = true
  end

  def public_action
    @access_checked = true
  end

  def unauthorized
    reset_session
    render 'errors/unauthorized', status: :unauthorized
  end

  def forbidden
    render 'errors/forbidden', status: :forbidden
  end
end
```

##### RSpec shared examples
``` ruby
require 'spec_helper'

require 'gumboot/shared_examples/application_controller'

RSpec.describe ApplicationController, type: :controller do
  include_examples 'Application controller'
end
```

### RESTful API

#### Versioning

All AAF API **must** be versioned by default.

Clients **must** supply an Accept header with all API requests. It must specify the version of API which the client is expecting to communicate with:

```
Accept: application/vnd.aaf.<your application name>.vX+json
```

For example a client communicating with the *example* application and using v1 of the API would be required to send:

```
Accept: application/vnd.aaf.example.v1+json
```

Change within an API version number will only be by extension, either with additional endpoints being made available or additional JSON being added to currently documented responses. Either of these changes should not impact well behaved clients that correctly parse and use JSON as intended. Clients should be advised of this expectation before receiving access.

#### Client Errors

There are three possible types of client errors on API calls that receive request bodies:

* Sending invalid JSON will result in a 400 Bad Request response.
* Sending the wrong type of JSON values will result in a 400 Bad Request response.
* Sending invalid fields will result in a 422 Unprocessable Entity response.
* Sending invalid credentials will result in a 401 unauthorised response.
* Sending requests to resources for which the Subject has no permission will result in a 403 forbidden response.

Response errors will contain JSON with the 'message' or 'errors' values specified to give more visibility into what went wrong.

#### Documenting resources
TODO.

#### Responding to requests
To ensure all AAF API work the same a base controller for all API related controllers to extend from is recommended.

Having this controller live within an API module is recommended.

##### Contollers

###### Rails 4.x
See `spec/dummy/app/controllers/api/api_controller.rb` for the implementation this example is based on

```ruby
require 'openssl'

module API
  class APIController < ActionController::Base
    Forbidden = Class.new(StandardError)
    private_constant :Forbidden
    rescue_from Forbidden, with: :forbidden

    Unauthorized = Class.new(StandardError)
    private_constant :Unauthorized
    rescue_from Unauthorized, with: :unauthorized

    protect_from_forgery with: :null_session
    before_action :ensure_authenticated
    after_action :ensure_access_checked

    attr_reader :subject

    protected

    def ensure_authenticated
      # Ensure API subject exists and is functioning
      @subject = APISubject.find_by(x509_cn: x509_cn)
      fail(Unauthorized, 'Subject invalid') unless @subject
      fail(Unauthorized, 'Subject not functional') unless @subject.functioning?
    end

    def ensure_access_checked
      return if @access_checked

      method = "#{self.class.name}##{params[:action]}"
      fail("No access control performed by #{method}")
    end

    def x509_cn
      # Verified DN pushed by nginx following successful client SSL verification
      # nginx is always going to do a better job of terminating SSL then we can
      x509_dn = request.headers['HTTP_X509_DN'].try(:force_encoding, 'UTF-8')
      fail(Unauthorized, 'Subject DN') unless x509_dn

      x509_dn_parsed = OpenSSL::X509::Name.parse(x509_dn)
      x509_dn_hash = Hash[x509_dn_parsed.to_a
                          .map { |components| components[0..1] }]

      x509_dn_hash['CN'] || fail(Unauthorized, 'Subject CN invalid')

      rescue OpenSSL::X509::NameError
        raise(Unauthorized, 'Subject DN invalid')
    end

    def check_access!(action)
      fail(Forbidden) unless @subject.permits?(action)
      @access_checked = true
    end

    def public_action
      @access_checked = true
    end

    def unauthorized(exception)
      message = 'SSL client failure.'
      error = exception.message
      render json: { message: message, error: error }, status: :unauthorized
    end

    def forbidden(_exception)
      message = 'The request was understood but explicitly denied.'
      render json: { message: message }, status: :forbidden
    end
  end
end

```

##### RSpec shared examples
``` ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_controller'

RSpec.describe API::APIController, type: :controller do
  include_examples 'API base controller'
end
```

#### Routing requests
Routing to the appropriate controller for handling API requests **must** be undertaken using content within the Accept header.

##### Rails 4.x
Appropriate routing in a Rails 4.x application can be achieved as follows. Ensure you replace instances of *<your application name>* with something unique to the application i.e for the application named 'SAML service' we might use **`application/vnd.aaf.saml-service.v1+json`**

`lib/api_constraints.rb`

```ruby
class APIConstraints
  def initialize(version:, default: false)
    @version = version
    @default = default
  end

  def matches?(req)
    @default || req.headers['Accept'].include?(version_string)
  end

  private

  def version_string
    "application/vnd.aaf.<your application name>.v#{@version}+json"
  end
end
```

`config/routes.rb`

```ruby
require 'api_constraints'

<Your Application>::Application.routes.draw do

  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: APIConstraints.new(version: 1, default: true) do
      resources :xyz, param: :uid, only: [:show, :create, :update, :destroy]
    end
  end

end
```
This method has controllers living within the API::VX module and naturally extending the APIController documented above.

##### RSpec shared examples
``` ruby
require 'spec_helper'

require 'gumboot/shared_examples/api_constraints'

require 'api_constraints'

RSpec.describe APIConstraints do
  let(:matching_request) do
    double(headers: { 'Accept' => 'application/vnd.aaf.<your application name>.v1+json' })
  end
  let(:non_matching_request) do
    double(headers: { 'Accept' => 'application/vnd.aaf.<your application name>.v2+json' })
  end

  include_examples 'API constraints'
end
```

## Event Handling
TODO - Publishing and consuming events from AAF AMQP.
