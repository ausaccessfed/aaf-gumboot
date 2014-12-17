# AAF Gumboot
Subjects, APISubjects, Roles, Permissions, access control, RESTful APIs. 

Gumboot sloshes through these **muddy** topics for AAF applications but leaves the actual hard work upto developers because Gumboots do nothing on their own.

![](http://i.imgur.com/ImJXacR.jpg)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aaf-gumboot'
```

And then execute:

    $ bundle
	
## Usage

Before getting started it is **strongly recommended** that you ensure 'API' is an acronym within your application

e.g for Rails applications in config/initializers/inflections.rb

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end
```

### Models
All AAF applications **must** to provide all the following models.

Example implementations are provided for ActiveModel and Sequel below. Developers may extend models or implement them in any way they wish so long as the provided set of shared RSpec examples (discussed later) all pass.

For each model a FactoryGirl factory *must also be provided*.

#### Subject
A Subject is a security-specific 'view' of an application user. A Subject does not always need to reflect a human being. It is a representation of any entity that is doing something with the application.

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
      validates_presence [:x509_dn, :created_at, :updated_at]
    end
  end
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

### RESTful API
To ensure all AAF API work the same a base controller for all API related controllers to extend from is recommended.

Having this controller live within the API module is recommended.

#### Rails 4.x
```ruby
module API
  class APIController < ApplicationController
    Forbidden = Class.new(StandardError)
    private_constant :Forbidden
    rescue_from Forbidden, with: :forbidden

    protect_from_forgery with: :null_session
    before_action :permitted?

    attr_reader :subject

    after_action do
      unless @access_checked
        method = "#{self.class.name}##{params[:action]}"
        fail("No access control performed by #{method}")
      end
    end

    protected

    def permitted?
      # Verified DN pushed by nginx following successful client SSL verification
      # Nginx is always going to do a better job of terminating SSL then we can
      @x509_dn = request.headers['HTTP_X509_DN']
                 .try(:force_encoding, 'UTF-8')

      head :unauthorized unless @x509_dn

      # Ensure API subject exists and is functioning
      # TODO: Modify if using Sequel
      @subject = APISubject.find_by x509_dn: @x509_dn
    end

    def check_access!(action)
      fail(Forbidden) unless @subject.permits?(action)
      @access_checked = true
    end

    def public_action
      @access_checked = true
    end

    def forbidden
      render nothing: true, status: 403
    end
  end
end
```

## Testing
This is the core piece of Gumboot, a set of shared specifications that all applications must make use of. Your application should provide a set of specs which include shared specifications as shown below.

## Models

### Subject

TODO

### API Subject

```ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_subjects'

RSpec.describe API::APISubject, type: :model do
  include_examples 'API Subjects'
  
  # TODO: examples for your model extensions here
end
```

### Role
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/roles'

RSpec.describe Role, type: :model do
  include_examples 'Roles'
  
  # TODO: examples for your model extensions here
end
```

### Permission
```ruby
require 'rails_helper'

require 'gumboot/shared_examples/permissions'

RSpec.describe Permission, type: :model do
  include_examples 'Permissions'
  
  # TODO: examples for your model extensions here
end
```

## RESTful API

### API Base
``` ruby
require 'rails_helper'

require 'gumboot/shared_examples/api_controller'

RSpec.describe API::APIController, type: :controller do
  include_examples 'API base controller'
end
```

