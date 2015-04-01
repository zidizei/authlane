require 'sinatra/base'
require 'sinatra/cookies'

require 'authlane/version'
require 'authlane/serializeduser'
require 'authlane/helper'

module Sinatra
  ##
  # The `AuthLane` Sinatra Extension allows easy User
  # authentication with support for different User *roles*
  # and automatic login via Cookies. It exposes {Sinatra::AuthLane::Helpers Helper}
  # methods to tell which routes are protected or involved in the authentication process.
  #
  # The actual authentication logic (*strategy*) is defined by the Application using
  # a namespaced DSL provided by this extension, while the general Extension configuration
  # is handled with Sinatra's `set` method, which will be described in more detail below.
  #
  # # Configuring AuthLane
  #
  # **AuthLane**'s configuration data is available under Sinatra's `settings` object
  # with the key `:authlane` as a Hash, so changing config values is simply done with
  # Sinatra's `set` method.
  #
  # ```
  # set :authlane, :failed_route => '/login'
  # ```
  #
  # The following settings can be customize (the used values are their defaults):
  #
  # ```
  # set :authlane, :failed_route    => '/user/unauthorized',
  #                :session_key     => :authlane,
  #                :remember_cookie => :authlane_token,
  #                :serialize_user  => [:id]
  # ```
  #
  # ## `:failed_route`
  #
  # The `:failed_route` sets the route String, where AuthLane should redirect to in case a
  # route requires authorisation and the User ist not logged in. It typically is the route
  # to display the login form, but can be set to anything that is needed, as long the it is
  # not protected by authorisation as well.
  #
  # ## `:session_key`
  #
  # The `:session_key` sets the name (as a Symbol) of the Session variable where User credentials of a logged in
  # User are stored. The stored User data are wrapped inside a {Sinatra::AuthLane::SerializedUser SerializedUser}
  # object and can be retrieved by using Sinatra's `session` helper and giving it the key that is defined here
  # `session[:authlane]`. Alternatively, the AuthLane {Sinatra::AuthLane::Helpers Helper} exposes the method
  # {Sinatra::AuthLane::Helpers#current_user current_user} to provide easy access to User data.
  #
  # ## `:remember_cookie`
  #
  # Customize the Cookie's name that stores the token hash used for the *Remember Me* functionality.
  # The setting (and creation) of the token needs to be implemented by the Extension user in
  # both the Auth and Remember Strategy.
  #
  # ## `:serialize_user`
  #
  # The `:serialized_user` settings contains an Array of Symbols telling AuthLane which attributes
  # of the User model that is used to identify Application useres should
  # be serialized into {Sinatra::AuthLane::SerializedUser SerializedUser}. It is recommended to not
  # store the whole User object, but note that the *id* (or however the unique identifier
  # of the object is named) attribute is required.
  #
  module AuthLane
    ##
    # Initiates **AuthLane** when it is being registered with a Sinatra Application.
    #
    # Adds helper methods to App instance and sets the default
    # settings described above.
    #
    # @todo Don't pass `app` to instance variable `@app`. Implement proper encapsulation of AuthLane.
    #
    # @api Sinatra
    #
    def self.registered(app)
      app.helpers AuthLane::Helpers

      @app = app

      # default configuration
      app.set :authlane,
        :failed_route      => '/user/unauthorized',   # route to redirect to if the user is required to login
        :session_key       => :authlane,              # name of the Session key to store the login data
        :remember_cookie   => :'authlane.token',      # Cookie name to store 'Remember Me' token
        :auth_strategy     => Proc.new { false },     # strategy to be executed to log in users
        :role_strategy     => { roles: Proc.new { true } },      # strategy to be executed to check permissions and roles
        :remember_strategy => Proc.new { false },     # strategy to be executed to log in users via 'Remember Me' token
        :forget_strategy   => Proc.new { false },     # strategy to be executed when logging out and 'forgetting' the user
        :serialize_user    => [:id]                   # specify User model fields to be serialized into the login session
                                                      # or define a custom class which receives the whole User model to handle by itself
    end

    class << self
      ##
      # Create the **Auth** *Strategy* for AuthLane.
      #
      # Used from the Sinatra DSL context to define the **Auth** *Strategy*
      # to be used by passing the implementation as a Code block. It is then
      # stored as a `Proc` object and will be called by AuthLane when needed.
      #
      # To see the code block's objects API requirements, refer to the {https://github.com/zidizei/authlane/wiki Wiki}.
      #
      # @note While the **Auth** Strategy is primarily responsible for logging in users,
      #   it usually needs to implement some *Remember Me* logic as well.
      #
      # @return [Proc] the `Proc` object of the strategy.
      #
      # @example
      #   Sinatra::AuthLane.create_auth_strategy do
      #     user = User.find_by_username(params[:username])
      #
      #     (!user.nil? && user.password == params[:pass]) ? user : false
      #   end
      #
      # @see Sinatra::AuthLane::Helpers#authorize! authorize!
      #
      # @api AuthLane
      #
      def create_auth_strategy
        strat = Proc.new

        @app.set :authlane, :auth_strategy => strat
        strat
      end

      ##
      # Create the **Role** *Strategy* for AuthLane.
      #
      # Used from the Sinatra DSL context to define the **Role** *Strategy*
      # to be used by passing the implementation as a Code block. It is then
      # stored as a `Proc` object and will be called by AuthLane when needed.
      #
      # To see the code block's API requirements, refer to the {https://github.com/zidizei/authlane/wiki Wiki}.
      #
      # @example
      #   Sinatra::AuthLane.create_role_strategy do |roles|
      #     user = current_user         # AuthLane helper to get the currently logged in user data
      #
      #     roles.include? user.role    # See if the list of role names in `roles` contains the user's role
      #   end
      #
      # @param [Symbol] name The name of the role strategy.
      #
      # @return [Proc] the `Proc` object of the strategy.
      #
      # @see Sinatra::AuthLane::Helpers#authorized? authorized?
      #
      # @api AuthLane
      #
      def create_role_strategy(name = :roles)
        strat = Proc.new

        @app.settings.authlane[:role_strategy][name] = strat
        strat
      end

      ##
      # Create the **Remember** *Strategy* for AuthLane.
      #
      # Used from the Sinatra DSL context to define the **Remember** *Strategy*
      # to be used by passing the implementation as a Code block. It is then
      # stored as a `Proc` object and will be called by AuthLane when needed.
      #
      # To see the code block's API requirements, refer to the {https://github.com/zidizei/authlane/wiki Wiki}.
      #
      # @note The **Remember** Strategy is only responsible for automatically logging in a user.
      #   The necessary Cookie token (plus any additional logic) is usually set in the **Auth** Strategy.
      #
      # @example
      #   Sinatra::AuthLane.create_remember_strategy do |token|
      #     remembered_user = User.find_by_token(token)
      #
      #     (remembered_user.nil?) ? false : remembered_user
      #   end
      #
      # @return [Proc] the `Proc` object of the strategy.
      #
      # @see Sinatra::AuthLane::Helpers#authorized? authorized?
      #
      # @api AuthLane
      #
      def create_remember_strategy
        strat = Proc.new

        @app.set :authlane, :remember_strategy => strat
        strat
      end

      ##
      # Create the **Forget** *Strategy* for AuthLane.
      #
      # Used from the Sinatra DSL context to define the **Forget** *Strategy*
      # to be used by passing the implementation as a Code block. It is then
      # stored as a `Proc` object and will be called by AuthLane when needed.
      #
      # To see the code block's API requirements, refer to the {https://github.com/zidizei/authlane/wiki Wiki}.
      #
      # @note The **Forget** Strategy is the counter-part to the **Remember** Strategy.
      #   It's responsible for disabling the auto login technique and is called when logging out.
      #
      # @note While the *Auth Strategy* needs to interact with the Cookie token directly,
      #   the *Forget Strategy* does not need to implement the deletion of the Cookie.
      #   This is done automatically by AuthLane behind the scenes.
      #
      # @example
      #   Sinatra::AuthLane.create_forget_strategy do |token|
      #     user = User.find(current_user.id)
      #     user.token = nil if user.token == token
      #   end
      #
      # @see Sinatra::AuthLane::Helpers#unauthorize! unauthorize!
      #
      # @return [Proc] the `Proc` object of the strategy.
      #
      # @api AuthLane
      #
      def create_forget_strategy
        strat = Proc.new

        @app.set :authlane, :forget_strategy => strat
        strat
      end
    end
  end

  helpers Sinatra::Cookies
  register Sinatra::AuthLane
end
