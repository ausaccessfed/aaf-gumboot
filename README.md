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
Copyright 2014-2017, Australian Access Federation

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

## Your local development environment
Before you get started you should ensure your development machine has the following files located under `~/.aaf`.

1. `rapidconnect.yml`

    Generate a secret to use with Rapid Connect with the following:

        $> LC_CTYPE=C tr -dc '[[:alnum:][:punct:]]' < /dev/urandom | head -c32 ;echo

    Access [https://rapid.test.aaf.edu.au](https://rapid.test.aaf.edu.au) and register using your secret created above and the callback URL of `http://localhost:8080/auth/jwt`

    Upon successful registration you cannot simply use the URL Rapid Connect provides by team. Request one of the team change your registration to be of the type `AU Research`. They can then provide you the appropriate URL to enter below.

    Edit your `rapidconnect.yml` to contains:

    ``` ruby
    ---
    url: 'https://rapid.test.aaf.edu.au/jwt/authnrequest/.....'
    secret: '<you generated this>'
    issuer: 'https://rapid.test.aaf.edu.au'
    audience: 'http://localhost:8080'
    ```

2. Create a key for use with event code called `event_encryption_key.pem` via the command `openssl genrsa -out ~/.aaf/event_encryption_key.pem 2048`

3. Create a key and CSR for use with access to other AAF application API endpoints.

    1. `openssl genrsa -out api-client.key 2048`
    2. `openssl req -new -key api-client.key -out api-client.csr -subj '/CN=Your Name Here/'`
    2. Access [https://certs.aaf.edu.au/](https://certs.aaf.edu.au/)
    3. Request a certificate under `Australian Access Federation` provide your CSR and select the CA 'AAF API Client CA'
    4. Wait for approval
    5. One approved your certificate link will be sent to you in email, download this file
    6. Record the certificate CN, you will need this in the future
    7. Rename the downloaded file as api-client.crt

Here is what your `~/.aaf` should end up looking like:

```
$ ls -l

total 32

api-client.crt
api-client.key
event_encryption_key.pem
rapidconnect.yml
```

## General advice for AAF Ruby applications
For AAF staff this document assumes you've already read and are following the more general AAF [development workflow](https://github.com/ausaccessfed/developmentworkflow).

### Code Comments
In general AAF ruby based applications don't need 'default' or 'generated' comments committed to our code. We're all experienced developers so this kind of extraneous comment doesn't make sense in our space. You should remove these prior to submitting PR.

Of course ACTUAL comments describing something you've written that is a little bit odd or unusual are very much welcome.

## Gems
The way we build ruby applications has tried to be standardised as much as possible at a base layer. You're likely going to want all these Gems in your Gemfile for a Rails app or a considerable subset of them for a non Rails app.

```ruby
gem 'mysql2'
gem 'rails', '>= 5.0.0', '< 5.1' # Ensure latest release

gem 'aaf-secure_headers'
gem 'aaf-lipstick'
gem 'accession'
gem 'valhammer'

gem 'god', require: false
gem 'puma', require: false

gem 'local_time'

gem 'rails_admin'
gem 'rails_admin_aaf_theme'

group :development, :test do
  gem 'aaf-gumboot'
  gem 'bullet'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'guard', require: false
  gem 'guard-brakeman', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'pry'
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 3.5.0.beta4'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'timecop'
  gem 'web-console', '~> 2.0', require: false
  gem 'webmock', require: false
end
```

Execute:

    $ bundle

## Guard
Gumboot projects make use of Guard, Rubocop, RSpec and Brakeman.

To get this all up and running you should execute:

    $ bundle exec guard init

The result will be a reasonably complete `Guardfile`. As described earlier you can remove the default comments that are generated and also references to the Turnip project which we don't utilise.

### RSpec
Execute:

    $ bundle exec rails generate rspec:install

Modify the generated RSpec config file as follows `.rspec`:

```
--color
--require spec_helper
--format documentation
```

### Rubocop
Add a Rubocop config file `.rubocop.yml`:

```
inherit_gem:
  aaf-gumboot: aaf-rubocop.yml
```

### Simplecov
Add a simplecov config file `.simplecov`:

```
SimpleCov.start('rails') do
  minimum_coverage 100
end
```

Edit `spec/spec_helper.rb` and add

``` ruby
require 'simplecov'
```

## Git Ignore
This needs to be customised per application but be sure it excludes **all** local config files, keys, certificates and anything else containing secrets. For example:

```
# TODO this is application specific
config/xyz_service.yml

config/rapidconnect.yml
config/api-client.*
config/event_encryption_key.pem
spec/examples.txt

coverage
tmp
log
vendor
.DS_Store
```

## Acronyms
Ensure 'API' is an acronym within your application:

e.g for Rails applications in config/initializers/inflections.rb

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end
```
## Authentication and Identity (1 of 2)
There are two options for AAF applications to authenticate and obtain identity
information for subjects, Rapid Connect and SAML/Shibboleth.
Unless otherwise specified for your project default to using Rapid Connect.

### Rapid Connect using rapid-rack gem

#### Gemfile
Add the following gem to your Gemfile in the default group:

``` ruby
gem 'rapid-rack'
gem 'super-identity'
```

Execute:

    $ bundle

#### Authentication Receiver
To utilise Rapid Connect your application will require a receiver class
which will receive the validated claim from Rapid Connect and establish a
session for the authenticated subject.

As an initial step our receiver class will be a no-op. You'll implement the receiver, in full, later in this document.

Create `lib/authentication.rb`:

``` ruby
# frozen_string_literal: true
module Authentication
end

require 'authentication/subject_receiver'
```

Create `lib/authentication/subject_receiver.rb`:

``` ruby
# frozen_string_literal: true
module Authentication
  class SubjectReceiver
    include RapidRack::DefaultReceiver
    include RapidRack::RedisRegistry
    include SuperIdentity::Client

    def map_attributes(_env, attrs)
      {}
    end

    def subject(_env, attrs)
    end
  end
end
```

#### Configure receiver
Add the following to `config/application.rb`:

``` ruby
config.autoload_paths += [
  File.join(config.root, 'lib')
]
config.rapid_rack.receiver = 'Authentication::SubjectReceiver'
```

#### Configure routes
Add the following to `config/routes.yml`:

``` ruby
mount RapidRack::Engine => '/auth'
```

### SAML/Shibboleth using saml-rack gem
**TODO**: This needs to be written along with finalisation of the shib-rack readme,
currently being authored at https://github.com/ausaccessfed/shib-rack under the
`feature/readme` branch. This section should essentially mirror the above for
Rapid Connect given the concepts in each gem are reasonably similar.

## Setup
All AAF applications utilise a standard setup process. This makes it easier for
developers who are new to a project as all you should need to know to get
started is `./bin/setup`. In addition this helps with merging in additional
config options as projects grow.

### Service specific config

Most of our applications require unique configuration at deployment time and we structure this within a standard location of `config/xyz_service.yml.dist`. Replace **xyz** with the name of your application. e.g. For bigboot-service, you'd use `config/bigboot_service.yml.dist`

### Create a custom setup script for your application

The general structure of your `./bin/setup` file should be as follows:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

Dir.chdir File.expand_path('..', File.dirname(__FILE__))

puts '== Installing dependencies =='
system 'gem install bundler --conservative'
system 'bundle check || bundle install'

require 'bundler/setup'
require 'gumboot/strap'

include Gumboot::Strap

puts "\n== Installing configuration files =="

link_global_configuration %w(api-client.crt api-client.key event_encryption_key.pem)

# Rapid Connect Applications must enable this
# link_global_configuration %w(rapidconnect.yml)

# TODO: Name this per your local app
update_local_configuration %w(xyz_service.yml)

puts "\n== Loading Rails environment =="
require_relative '../config/environment'

ensure_activerecord_databases(%w(test development))
maintain_activerecord_schema
clean_logs
clean_tempfiles
```

You can find task details (or add new ones) at [https://github.com/ausaccessfed/aaf-gumboot/blob/develop/lib/gumboot/strap.rb](https://github.com/ausaccessfed/aaf-gumboot/blob/develop/lib/gumboot/strap.rb).

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
  username: xyz_app
  password: password
  host: 127.0.0.1
  pool: 5
  encoding: utf8
  collation: utf8_bin

development:
  <<: *default
  database: xyz_development

test:
  <<: *default
  database: xyz_test

production:
  <<: *default
  username: <%= ENV['XYZ_DB_USERNAME'] %>
  password: <%= ENV['XYZ_DB_PASSWORD'] %>
  database: <%= ENV['XYZ_DB_NAME'] %>
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
  # Use the following (as an example) for column based exemptions
  let(:collation_exemptions) { { table_name: %i[column_name] } }

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
    mysql -e 'ALTER DATABASE COLLATE = utf8_bin' xyz_development
    mysql -e 'ALTER DATABASE COLLATE = utf8_bin' xyz_test
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
    roles.joins(:permissions).pluck('permissions.value')
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
An API Subject is an extension of the Subject concept reserved specifically for Subjects that utilise x509 client certificate verification to make requests to the applications RESTful API endpoints. x509_cn client certificates **MUST** be unique.

#### Active Model
``` ruby
class APISubject < ActiveRecord::Base
  include Accession::Principal

  has_many :api_subject_roles
  has_many :roles, through: :api_subject_roles

  valhammer
  validates :x509_cn, format: { with: /\A[\w-]+\z/ }

  def permissions
    # This could be extended to gather permissions from
    # other data sources providing input to api_subject identity
    roles.joins(:permissions).pluck('permissions.value')
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
    validates_format /\A[\w-]+\z/, :x509_cn
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

## Authentication and Identity (2 of 2)
You should now follow the documention for [https://github.com/ausaccessfed/rapid-rack](https://github.com/ausaccessfed/rapid-rack) or [https://github.com/ausaccessfed/shib-rack](https://github.com/ausaccessfed/shib-rack) depending on how your application is handling authentication and identity to complete your receiver implementation.

## Access Control

**TODO**

## Controllers

AAF applications must utilise controllers which default to verifying authentication
and access control on every request. This can be changed as implementations require
to be publicly accessible for example but must be explicitly configured in code to make it clear to all.

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

**TODO**

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

## Event Handling

**TODO** - Publishing and consuming events from AAF SQS.

## Continuous Integration

**TODO**

``` ruby
# frozen_string_literal: true
begin
  require 'rubocop/rake_task'
  require 'brakeman'
rescue LoadError
  :production
end

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

RuboCop::RakeTask.new if defined? RuboCop

task :brakeman do
  Brakeman.run app_path: '.', print_report: true, exit_on_warn: true
end

task default: [:rubocop, :spec, :brakeman]
```
