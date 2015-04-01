# AuthLane

The **AuthLane** Sinatra Extension allows easy User authentication with support for different User *roles* and automatic login via Cookies. It exposes Helper methods to tell which routes are protected or involved in the authentication process.

The actual authentication logic (*strategy*) is defined by the Application using a namespaced DSL provided by this extension, while the general Extension configuration is handled with Sinatra's `set` method, which will be described in more detail below.

## Installation

Get the Gem:

```
gem install authlane
```

Or let Bundler do the work:

``` ruby
# Gemfile
gem 'authlane'
```

**AuthLane** utilizes the standard Sinatra Extension format for *classic*-style applications:

``` ruby
require 'sinatra'
require 'sinatra/authlane'

get '/user' do
  protect!

  # Application stuff for signed in users ....
end
```

As well as `modular`-style applications:

``` ruby
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/authlane'

class App < Sinatra::Base
  register Sinatra::AuthLane
  helpers Sinatra::Cookies

  get '/user' do
    protect!

    # Application stuff for signed in users
  end
end
```

## Configuration

**AuthLane**'s configuration data is available under Sinatra's `settings` object with the key `:authlane` as a Hash, so changing config values is simply done with Sinatra's `set` method.

``` ruby
set :authlane, :failed_route => '/login'
```

The following settings can be customize (the used values are their defaults):

``` ruby
set :authlane, :failed_route    => '/user/unauthorized',
               :session_key     => :authlane,
               :remember_cookie => :authlane_token,
               :serialize_user  => [:id]
```

#### `:failed_route`

The `:failed_route` sets the route String, where AuthLane should redirect to in case a route requires authorization and the User is not logged in. It typically is the route to display the login form, but can be set to anything that is needed, as long the it is not protected by authorization as well.

#### `:session_key`

The `:session_key` sets the name (as a Symbol) of the Session variable where User credentials of a logged in User are stored. The stored User data are wrapped inside a `SerializedUser` object and can be retrieved by using Sinatra's `session` helper and giving it the key that is defined here `session[:authlane]`. Alternatively, the AuthLane Helper exposes the method `current_user` to provide easy access to User data.

#### `:remember_cookie`

Customize the Cookie's name that stores the token hash used for the *Remember Me* functionality. The setting (and creation) of the token needs to be implemented by the Extension user in both the *auth* and *remember* strategy.

#### `:serialize_user`

The `:serialized_user` settings contains an Array of Symbols telling AuthLane which attributes of the User model that is used to identify Application users should be serialized into a `SerializedUser` object. It is recommended to not store the whole User object, but note that the *id* (or however the unique identifier of the object is named) attribute is required.

Alternatively, you can specify your own Class to be used.

``` ruby
set :authlane, :serialize_user => CustomUser
```

The `CustomUser`'s `initialize` method receives one argument, which is the User object. What that object is exactly depends on your **Auth strategy** implementation. Basically, it's the User data coming from your application's persisting backend, like a database.

``` ruby
class CustomUser
  attr_reader :id

  def initialize(user)
    @id = user.id
  end
end
```

It is possible to have attribute accessors in your custom Class, but beware that **AuthLane** will *not* save changes back to your backend.
