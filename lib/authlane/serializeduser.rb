
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
            @user[attrs] = user.__send__(attrs.to_sym) if user.respond_to? attrs
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
          @user[m]
        else
          @user.__send__(m.to_sym, args)
        end
      end

      ##
      # Return a Hash representing the serialized object's attributes and values.
      #
      # If the whole Object was stored its `to_h` will be called.
      # In either case, attribute names can be accessed by Symbol or String
      # key alike.
      #
      # @return [Hash] the Hash representation of the stored object.
      #
      def to_h
        universal_hash = Hash.new
        hash = @user.to_h
        hash.each_pair do |key, value|
          universal_hash[key.to_s] = value if key.is_a? Symbol

          universal_hash[key] = value
        end

        universal_hash
      end
    end
  end
end
