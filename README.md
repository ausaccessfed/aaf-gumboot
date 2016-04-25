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
[DS img]: https://img.shields.io/gemnasium/ausaccessfed/aaf-gumboot.svg
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
gem 'rails', '4.2.3' # Ensure latest release
gem 'mysql2'

gem 'rapid-rack'
gem 'valhammer'
gem 'accession'
gem 'aaf-lipstick'

gem 'unicorn', require: false
gem 'god', require: false

group :development, :test do
  gem 'rspec-rails', '~> 3.3.0'
  gem 'shoulda-matchers'

  gem 'factory_girl_rails'
  gem 'faker'
  gem 'timecop'
  gem 'database_cleaner'

  gem 'rubocop', require: false
  gem 'simplecov', require: false

  gem 'capybara', require: false
  gem 'poltergeist', require: false
  gem 'phantomjs', require: 'phantomjs/poltergeist'

  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-rspec', require: false
  gem 'guard-brakeman', require: false
  gem 'terminal-notifier-guard', require: false

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

## Database

### Configuration

**Note:** This is only applicable to applications using MySQL / MariaDB.

We use the following conventions for naming around databases:

Username: `xyz_app` - where xyz represents the name of your application. In most
cases this will be xyz-service, you should drop the `-service`.

e.g. For bigboot-service, you'd use `bigboot_app`

Database name: `xyz_#{env}` - where xyz represents the name of your application.
In most cases this will be xyz-service, you should drop the `-service`.

e.g. For bigboot-service, you'd use `bigboot_development` for development.

### Example Configuration

The following example should form the basis of project database configuration.
It is ready to be used for local development/test, for codeship CI and with AAF
production defaults.

```yaml
default: &default
  adapter: mysql2
  username: example_app
  password: password
  host: 127.0.0.1
  pool: 5
  encoding: utf8
  collation: utf8_bin

development:
  <<: *default
  database: example_development

test:
  <<: *default
  database: example_test

production:
  <<: *default
  username: <%= ENV['EXAMPLE_DB_USERNAME'] %>
  password: <%= ENV['EXAMPLE_DB_PASSWORD'] %>
  database: <%= ENV['EXAMPLE_DB_NAME'] %>
```

### UTF8 and binary collation

The example config above will ensure your database connection is using
the `utf8` character set, and `utf8_bin` collation which is required for all
AAF applications.

However you *MUST* also create a migration which ensures the correct setting
is applied at the database level:

```ruby
class ChangeDatabaseCollationToBinary < ActiveRecord::Migration
  def change
    execute('ALTER DATABASE COLLATE = utf8_bin')
  end
end
```

Before creating any further migrations, add the RSpec shared examples which
validate the encoding and collation of your schema:

```ruby
# spec/models/schema_spec.rb

require 'rails_helper'
require 'gumboot/shared_examples/database_schema'

RSpec.describe 'Database Schema' do
  let(:connection) { ActiveRecord::Base.connection.raw_connection }

  include_context 'Database Schema'
end
```

#### Existing Applications

For any existing app which adopts this set of tests, it is not sufficient to
change the configuration and run all migrations again on a clean database. All
tables which predate the configuration change MUST have a migration created
which alters their collation (to ensure test / production environments have the
correct database schema). This can be done per table as follows:

```ruby
class ChangeTableCollationToBinary < ActiveRecord::Migration
  def change
    execute('ALTER TABLE my_objects COLLATE = utf8_bin')
    execute('ALTER TABLE my_objects CONVERT TO CHARACTER SET utf8 ' \
            'COLLATE utf8_bin')
  end
end
```

The change in collation will not be reflected in `db/schema.rb`, but will still
be applied correctly during `rake db:schema:load` due to the new database
collation setting.

### Continuous Integration environments

An often-seen pattern on CI servers is to use a database which was created
out-of-band before permissions were granted to access the database. This very
rarely results in the correct collation setting for the database.

There are two ways we can address this easily:

1.  Drop and create the database again before loading the schema or running
    migrations. For example:

    ```
    bundle exec rake db:drop db:create db:schema:load
    ```

2.  Alter the collation of the database using the `mysql` command line client
    (ensure to alter both the `test` and `development` databases when using this
    method). For example:

    ```
    mysql -e 'ALTER DATABASE COLLATE = utf8_bin' my_app_development
    mysql -e 'ALTER DATABASE COLLATE = utf8_bin' my_app_test
    ```

Also note that some CI platforms will automatically set your
`config/database.yml` (thus **overwriting your collation settings**).
For Codeship refer to [https://codeship.com/documentation/databases/](https://codeship.com/documentation/databases/) to configure your database
correctly.

## Models
All AAF applications **must** provide the following models.

Example implementations are provided for ActiveModel and Sequel below. Developers may extend models or implement them in any way they wish.

For each model a FactoryGirl factory *must also be provided*.

For each model the provided RSpec shared examples **must** be used within your application and **must** pass.

### Subject
A Subject represents state and security operations for a single application user.

#### Active Model
```ruby
class Subject < ActiveRecord::Base
  include Accession::Principal

  has_many :subject_roles
  has_many :roles, through: :subject_roles

  valhammer

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
#### Sequel
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

#### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/subjects'

RSpec.describe Subject, type: :model do
  include_examples 'Subjects'

  # TODO: examples for your model extensions here
end
```

### API Subject
An API Subject is an extension of the Subject concept reserved specifically for Subjects that utilise x509 client certificate verification to make requests to the applications RESTful API endpoints.

#### Active Model
``` ruby
class APISubject < ActiveRecord::Base
  include Accession::Principal

  has_many :api_subject_roles
  has_many :roles, through: :api_subject_roles

  valhammer

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
```

#### Sequel
``` ruby
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
```

#### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_subjects'

RSpec.describe APISubject, type: :model do
  include_examples 'API Subjects'

  # TODO: examples for your model extensions here
end
```

### Role
The term *Role* is thrown around a lot and it's meaning is very diluted. For our purposes a Role is really a collection of permissions and a collection of Subjects for whom each associated permission is applied.

#### Active Record
``` ruby
class Role < ActiveRecord::Base
  has_many :api_subject_roles
  has_many :api_subjects, through: :api_subject_roles

  has_many :subject_roles
  has_many :subjects, through: :subject_roles

  has_many :permissions

  valhammer
end
```

#### Sequel
``` ruby
class Role < Sequel::Model
  one_to_many :permissions

  many_to_many :api_subjects
  many_to_many :subjects

  def validate
    super
    validates_presence [:name]
  end
end
```

#### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/roles'

RSpec.describe Role, type: :model do
  include_examples 'Roles'

  # TODO: examples for your model extensions here
end
```

### Permission
Permissions are the lowest level constructs in security policies. They describe which actions a Subject is able to perform or data the Subject is able to access.

#### Active Record
``` ruby
class Permission < ActiveRecord::Base
  belongs_to :role

  valhammer

  validates :value, format: Accession::Permission.regexp
end
```

#### Sequel
``` ruby
class Permission < Sequel::Model
  many_to_one :role

  def validate
    super
    validates_presence [:role, :value]
  end
end
```

#### RSpec shared examples
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/permissions'

RSpec.describe Permission, type: :model do
  include_examples 'Permissions'

  # TODO: examples for your model extensions here
end
```

### Foreign Keys

Rails 4.2 and above support a new foreign keys DSL. This is feature is not presently enabled in all databases [see supported database list](http://edgeguides.rubyonrails.org/4_2_release_notes.html#foreign-key-support) but you can safely integrate this supplied tests regardless of database.

#### Adding Foreign Keys

Include these foreign keys in a relevant migration.

```ruby
add_foreign_key 'api_subject_roles', 'api_subjects'
add_foreign_key 'api_subject_roles', 'roles'
add_foreign_key 'permissions', 'roles'
add_foreign_key 'subject_roles', 'roles'
add_foreign_key 'subject_roles', 'subjects'
```

#### RSpec shared examples

The shared examples will **only** be run if your current database configuration supports foreign keys. Otherwise they will be safely ignored by rspec at runtime.

**Important Note:** These specs are **ONLY** valid for ActiveRecord. Sequel users should implement their own specs to test foreign keys meet the required specification.  

```ruby
require 'rails_helper'

require 'gumboot/shared_examples/foreign_keys'

RSpec.describe 'Foreign Keys' do
  include_examples 'Gumboot Foreign Keys'

  # TODO: examples for your foreign key extensions here

end
```


## Access Control
TODO

## Controllers

AAF applications must utilise controllers which default to verifying authentication and access control on every request. This can be changed as implementations require to be publicly accessible for example but must be explicitly configured in code to make it clear to all.

##### Rails 4.x
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
    subject = session[:subject_id] && Subject.find_by(id: session[:subject_id])
    return nil unless subject.try(:functioning?)
    @subject = subject
  end

  protected

  def ensure_authenticated
    return force_authentication unless session[:subject_id]

    @subject = Subject.find_by(id: session[:subject_id])
    raise(Unauthorized, 'Subject invalid') unless @subject
    raise(Unauthorized, 'Subject not functional') unless @subject.functioning?
  end

  def ensure_access_checked
    return if @access_checked

    method = "#{self.class.name}##{params[:action]}"
    raise("No access control performed by #{method}")
  end

  def check_access!(action)
    raise(Forbidden) unless subject.permits?(action)
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

  def force_authentication
    session[:return_url] = request.url if request.get?

    redirect_to('/auth/login')
  end
end
```

#### RSpec shared examples
``` ruby
require 'rails_helper'

require 'gumboot/shared_examples/application_controller'

RSpec.describe ApplicationController, type: :controller do
  include_examples 'Application controller'
end
```

## RESTful API

### Versioning

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

### Client Errors

There are three possible types of client errors on API calls that receive request bodies:

* Sending invalid JSON will result in a 400 Bad Request response.
* Sending the wrong type of JSON values will result in a 400 Bad Request response.
* Sending invalid fields will result in a 422 Unprocessable Entity response.
* Sending invalid credentials will result in a 401 unauthorised response.
* Sending requests to resources for which the Subject has no permission will result in a 403 forbidden response.

Response errors will contain JSON with the 'message' or 'errors' values specified to give more visibility into what went wrong.

### Documenting resources
TODO.

### Responding to requests
To ensure all AAF API work the same a base controller for all API related controllers to extend from is recommended.

Having this controller live within an API module is recommended.

#### Controllers

##### Rails 4.x
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
      raise(Unauthorized, 'Subject invalid') unless @subject
      raise(Unauthorized, 'Subject not functional') unless @subject.functioning?
    end

    def ensure_access_checked
      return if @access_checked

      method = "#{self.class.name}##{params[:action]}"
      raise("No access control performed by #{method}")
    end

    def x509_cn
      # Verified DN pushed by nginx following successful client SSL verification
      # nginx is always going to do a better job of terminating SSL then we can
      raise(Unauthorized, 'Subject DN') if x509_dn.nil?

      x509_dn_parsed = OpenSSL::X509::Name.parse(x509_dn)
      x509_dn_hash = Hash[x509_dn_parsed.to_a
                          .map { |components| components[0..1] }]

      x509_dn_hash['CN'] || raise(Unauthorized, 'Subject CN invalid')

    rescue OpenSSL::X509::NameError
      raise(Unauthorized, 'Subject DN invalid')
    end

    def x509_dn
      x509_dn = request.headers['HTTP_X509_DN'].try(:force_encoding, 'UTF-8')
      x509_dn == '(null)' ? nil : x509_dn
    end

    def check_access!(action)
      raise(Forbidden) unless @subject.permits?(action)
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

#### RSpec shared examples
``` ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_controller'

RSpec.describe API::APIController, type: :controller do
  include_examples 'API base controller'
end
```

### Routing requests
Routing to the appropriate controller for handling API requests **must** be undertaken using content within the Accept header.

#### Rails 4.x
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
    scope constraints: APIConstraints.new(version: 1, default: true) do
      resources :xyz, param: :uid, only: [:show, :create, :update, :destroy]
    end
  end

end
```
This method has controllers living within the API::VX module and naturally extending the APIController documented above.

#### RSpec shared examples
``` ruby
require 'rails_helper'
require 'gumboot/shared_examples/api_constraints'

RSpec.describe APIConstraints do
  let(:matching_request) do
    headers = { 'Accept' => 'application/vnd.aaf.<your application name>.v1+json' }
    instance_double(ActionDispatch::Request, headers: headers)
  end
  let(:non_matching_request) do
    headers = { 'Accept' => 'application/vnd.aaf.<your application name>.v2+json' }
    instance_double(ActionDispatch::Request, headers: headers)
  end

  include_examples 'API constraints'
end
```

# Event Handling
TODO - Publishing and consuming events from AAF SQS.
