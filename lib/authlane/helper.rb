
module Sinatra
  module AuthLane
    ##
    # The **AuthLane** `Helpers` are helper methods that are made available to an application's
    # route definitions. It is the main interface between a Sinatra Application and AuthLane
    # and enables easy interaction with the authorization logic by calling a specific helper method.
    #
    module Helpers
      ##
      # @note This method uses {#authorized?} to decide, whether to redirect users to `failed_route`.
      # Check if a user is authorized to view a route.
      #
      # It utilizes the *Role* and *Remember Strategy* to see if a user can access the route this
      # helper method is called from. The first query inside this method is to look for logged in
      # user credentials in the Session. If this fails, *AuthLane* attempts to login the user
      # via Cookie token by calling the *Remember Strategy* that is defined for the application. If it succeeds,
      # this method will continue normally (as in the user was already logged in 'regularly') and
      # use the *Role Strategy* to check user privileges for the route, in case there were any specified when
      # it was being called.
      #
      # @example
      #   get '/account' do
      #     protect!
      #
      #     mustache :account
      #   end
      #
      #   get '/admin' do
      #     protect! roles: [:Admin],
      #              failed_route: '/account'
      #
      #     mustache :admin
      #   end
      #
      # @param [Array] roles A list of role/privilege requirements for a route, set to `nil` to ignore user roles
      # @param [String] failed_route Custom route to redirect to in case the user is not authorized
      #
      # @see Sinatra::AuthLane.create_role_strategy create_role_strategy
      # @see Sinatra::AuthLane.create_remember_strategy create_remember_strategy
      #
      def protect!(roles: nil, failed_route: nil)
        # check for custom :failed_route option
        failed_route ||= settings.authlane[:failed_route]

        redirect failed_route unless authorized?(roles: roles)
      end

      alias_method :protected, :protect!

      ##
      # @note For more information about how this method works, refer to {#protect!}.
      #
      # Returns a `Boolean` depending on the user's authorization status. This can be useful if
      # a route wants to handle unauthorized users differently than just redirecting them to the
      # `:failed_route` setting.
      #
      # @example
      #   get '/' do
      #     if authorized?
      #       mustache :welcome
      #     else
      #       mustache :whoareyou
      #     end
      #   end
      #
      # @param [Array] roles A list of role/privilege requirements for a route, set to `nil` to ignore user roles
      #
      # @return [Boolean] `true` if the user is authorized to view a route, `false` otherwise.
      #
      # @see Sinatra::AuthLane::Helpers#protect! protect!
      #
      def authorized?(roles: nil)
        # So, if session[settings.authlane[:session_key]] is available
        # we're home, otherwise, see if the 'Remember Me' strategy
        # can come up with some User credentials.
        if session[settings.authlane[:session_key]].nil?
          remember_strat = self.instance_eval(&settings.authlane[:remember_strategy])

          if remember_strat
            user = Sinatra::AuthLane::SerializedUser.new(remember_strat, settings.authlane[:serialize_user])

            # The strategy doesn't log in a User,
            # it just comes up with the credentials to do that.
            # The login actually happens right here.
            session[settings.authlane[:session_key]] = user
          end
        else
          user = session[settings.authlane[:session_key]]
        end

        if user.nil? || !user
          # Ok, looks like the User needs to gtfo.
          return false
        else
          # User is logged in ...
          unless roles.nil?
            # ... but hold up, he might not have the necessary
            # privileges to access this particular route.
            # Let's ask the 'Role' strategy.
            strat = self.instance_exec roles, &settings.authlane[:role_strategy]
            return false unless strat
          end
        end

        return true
      end

      ##
      # Marks a route as the login route, that typically receives `POST` data from a `<form>`.
      #
      # The actual handling of the login logic and anything else the application
      # requires is defined by creating the *Auth Strategy* using {Sinatra::AuthLane.create_auth_strategy create_auth_strategy}.
      # the code block will be called within `authorize!` and - depending on the outcome (refer to
      # {Sinatra::AuthLane.create_auth_strategy create_auth_strategy}'s documentation of its return value) - redirects
      # to the `:failed_route` AuthLane setting or lets the user 'through' to access the route, which - in most cases - should
      # be a redirect to the protected route.
      #
      # @example
      #   get '/signin' do
      #     mustache :signin
      #   end
      #
      #   post '/signin' do
      #     authorize!
      #
      #     redirect '/account'
      #   end
      #
      # @return [void]
      #
      # @see Sinatra::AuthLane.create_auth_strategy create_auth_strategy
      #
      def authorize!
        strat = self.instance_exec &settings.authlane[:auth_strategy]

        unless strat
          redirect settings.authlane[:failed_route], 303
        end

        session[settings.authlane[:session_key]] = Sinatra::AuthLane::SerializedUser.new(strat, settings.authlane[:serialize_user])
      end

      ##
      # Marks a route as the logout route.
      #
      # It resets the current Session and deletes any Session data along with it, particularly
      # the *AuthLane* Session data. The *Forget Strategy* will be called here as well to
      # 'counteract' the *Remember Me* functionality that is implemented in the *Remember* and
      # *Auth Strategy*.
      #
      # @example
      #   get '/signout' do
      #     unauthorize!
      #   end
      #
      # @return [void]
      #
      # @see Sinatra::AuthLane.create_forget_strategy create_forget_strategy
      #
      def unauthorize!
        token = cookies[settings.authlane[:remember_cookie]]

        self.instance_exec(token, &settings.authlane[:forget_strategy]) unless token.nil?

        # @private
        cookies.delete(settings.authlane[:remember_cookie])
        session.destroy
      end

      ##
      # Gets the credentials of the currently logged in user.
      #
      # @example
      #   get '/account' do
      #     authorized?
      #
      #     @username = current_user.username
      #     @email    = current_user[:email]    # This works too (refer to SerializedUser for more info)
      #
      #     mustache :account
      #   end
      #
      # @return [SerializedUser] the user data serialized into the Session.
      #
      def current_user
        session[settings.authlane[:session_key]]
      end
    end
  end
end
