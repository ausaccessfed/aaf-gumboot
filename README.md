# AAF Gumboot
Subjects, APISubjects, Roles, Permissions, Access Control, RESTful APIs, the endless stream of possible Gems. 

Gumboot sloshes through these **muddy** topics for AAF applications but leaves the actual hard work upto developers because Gumboots do nothing on their own.

![](http://i.imgur.com/ImJXacR.jpg)

## Gems

The way we build ruby applications has tried to be standardised as much as possible at a base layer. You're likely going to want all these Gems in your Gemfile for a Rails app or a considerable subset of them for a non Rails app.

```ruby
gem 'aaf-lipstick'
gem 'accession'
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
A Subject is a security-specific 'view' of an application user. A Subject does not always need to reflect a human being. It is a representation of any entity that is doing something with the application.

TODO.

#### APISubject
An API Subject is a logical extension of the Subject concept reserved specifically for representations entities that utilise x509 client certificate verification for making requests to our applications RESTful API endpoints.

Having this model live within the API module is recommended.

##### Active Model 
``` ruby
module API
  class APISubject < ActiveRecord::Base
    include Accession::Principal

    has_many :api_subject_roles
    has_many :roles, through: :api_subject_roles
    
    validates :x509_dn, presence: true
    validates :description, presence: true
    validates :email, presence: true

    def permissions
      # This could be extended to gather permissions from
      # other data sources providing input to api_subject identity
      roles.flat_map { |role| role.permissions.map(&:value) }
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

    def validate
      validates_presence [:x509_dn, :description, :email]
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
  has_many :permissions

  validates :name, presence: true
end
```

##### Sequel
``` ruby
class Role < Sequel::Model
  one_to_many :permissions
  many_to_many :api_subjects, class: 'API::APISubject'

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
  validates :value, presence: true
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

##### Rails 4.x
See spec/dummy/app/controllers/api/api_controller.rb for the implementation this example is based on

```ruby
require 'openssl'

module API
  class APIController < ApplicationController
    Forbidden = Class.new(StandardError)
    private_constant :Forbidden
    rescue_from Forbidden, with: :forbidden

    Unauthorized = Class.new(StandardError)
    private_constant :Unauthorized
    rescue_from Unauthorized, with: :unauthorized

    protect_from_forgery with: :null_session
    before_action :authenticated?

    attr_reader :subject

    after_action do
      unless @access_checked
        method = "#{self.class.name}##{params[:action]}"
        fail("No access control performed by #{method}")
      end
    end

    protected

    def authenticated?
      # Verified DN pushed by nginx following successful client SSL verification
      # nginx is always going to do a better job of terminating SSL then we can
      x509_dn = request.headers['HTTP_X509_DN'].try(:force_encoding, 'UTF-8')
      fail(Unauthorized, 'Subject DN') unless x509_dn

      x509_dn_parsed = OpenSSL::X509::Name.parse(x509_dn)
      x509_dn_hash = Hash[x509_dn_parsed.to_a
                          .map{ |components| components[0..1] }]
      x509_cn = x509_dn_hash['CN']
      fail(Unauthorized, 'Subject CN invalid') unless x509_cn

      # Ensure API subject exists and is functioning
      @subject = APISubject.find_by!(x509_cn: x509_cn)
      fail(Unauthorized, 'Subject not functional') unless @subject.functioning?
    rescue OpenSSL::X509::NameError
      fail(Unauthorized, 'Subject DN invalid')
    rescue ActiveRecord::RecordNotFound
      fail(Unauthorized, 'Subject invalid')
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
Appropriate routing in a Rails 4.x application can be achieved as follows

lib/api_constraints.rb

```ruby
class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    @default || req.headers['Accept'].include?("application/vnd.aaf.<your application name>.v#{@version}+json")
  end
end
```

config/routes.rb

```ruby
require 'api_constraints'

<Your Application>::Application.routes.draw do

  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :xyz, param: :uid, only: [:show, :create, :update, :destroy]
    end
  end

end
```
This method has controllers living within the API::VX module and naturally extending the APIController documented above.

##### RSpec shared examples
Not provided at this time.