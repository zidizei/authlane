
module Sinatra
  module AuthLane
    ##
    # Storage class for logged in user credentials.
    # Behaves like a Hash **and** an Object.
    #
    class SerializedUser
      ##
      # Sets up the Object to be serialized.
      #
      # Receives an Object `user` and stores its
      # attributes specified by `attributes` in a Hash.
      # If `attributes` is empty, the whole object
      # will be stored as-is.
      #
      # @param [Object] user The User object that needs to be serialized
      # @param [Array<Symbol>] attributes A list of attribute names to be serialized from `user`
      #
      def initialize(user, attributes = [])
        if attributes.size == 0
          @user = user
        else
          @user = Hash.new

          attributes.each do |attrs|
            if user.respond_to? attrs
              @user[attrs] = user.__send__(attrs.to_sym)
            elsif user.is_a?(Hash) and user.key? attrs
              @user[attrs] = user[attrs]
            end
          end
        end
      end

      ##
      # Access stored attributes like a Hash.
      #
      # If the whole Object was stored, it sends the
      # Hash key `a` as a message to that Object.
      #
      # @param [String, Symbol] a The name of the serialized object's attribute to be read
      #
      def [](a)
        (@user.is_a? Hash) ? @user[a] : @user.__send__(a.to_sym)
      end

      ##
      #
      #
      def []=(key, value)
        return if key.to_s == 'id'
        (@user.is_a? Hash) ? @user[key] = value : @user.__send__(key.to_sym, value)
      end

      ##
      # Enables Object-like access to the
      # stored attributes.
      #
      # If the whole Object was stored, it sends the
      # method name `m` as a message to that Object.
      # Otherwise it will access the Hash using `m` as
      # the key.
      #
      # @param [Symbol] m The name of the serialized object's attribute to be read
      #
      def method_missing(m, *args, &block)
        if @user.is_a? Hash
          if m.to_s.index('=').nil?
            @user[m]
          elsif m.to_s.index('id').nil?
            @user[m] = args[1]
          end
        else
          @user.__send__(m, args)
        end
      end

      ##
      # Return a Hash representing the serialized object's attributes and values.
      #
      # If the whole Object that was stored is a Hash itself, its `to_h` will be called.
      # Otherwise, the Object's instance methods are called and mapped to a Hash. This is
      # only the case when the passed user object is not a Hash and no specific **attributes**
      # for storage are set (see {#initialize})
      #
      # In either case, attribute names can be accessed by Symbol or String
      # key alike.
      #
      # @return [Hash] the Hash representation of the stored object.
      #
      def to_h
        universal_hash = Hash.new

        if @user.is_a? Hash
          hash = @user.to_h
        else
          hash = {}
          @user.class.instance_methods(false).each do |key|
            hash[key] = @user.__send__ key
          end
        end

        hash.each_pair do |key, value|
          universal_hash[key.to_s] = value if key.is_a? Symbol

          universal_hash[key] = value
        end

        universal_hash
      end
    end
  end
end
