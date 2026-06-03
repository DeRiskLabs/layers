# frozen_string_literal: true

module Layers

  module Graphql

    # The BaseEndpoint module connects GraphQL mutations and resolvers to user
    # stories declaratively.
    #
    # An including class names its user story with the user_story DSL and maps
    # resolver arguments with user_story_arg. The resolve entrypoint calls the
    # user story with the endpoint as listener, dispatching outcomes to the
    # on_success and on_failure methods the subclass must define.
    module BaseEndpoint

      class InvalidUserStory < Layers::Error; end

      # Error raised when a user_story_arg has been declared without a backing
      # method to resolve its value.
      class InvalidUserStoryArgumentMethod < Layers::Error

        def initialize(method_name)
          message = "A 'user_story_arg :#{method_name}' has been set, " \
            'however no method with this name has been defined.'
          super message
        end

      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods added to the including class
      #
      # Provides the user_story and user_story_arg declarations that wire the
      # endpoint to its user story.
      module ClassMethods

        def user_story(name_string)
          unless name_string.is_a?(String)
            fail ArgumentError, 'user_story argument must be a string'
          end
          @user_story_class_name = name_string.camelize
        end

        def user_story_class_name
          @user_story_class_name
        end

        def user_story_arg(arg, opts = {})
          user_story_args[arg] = opts
        end

        def user_story_args
          @user_story_args ||= {}
        end

      end


      attr_reader :initial_resolve_args


      def resolve(**resolve_args)
        return if context_has_errors?

        @initial_resolve_args = resolve_args.to_h

        execute!

      rescue StandardError => e
        raise GraphQL::ExecutionError, e.message
      end


      def success(**return_args)
        on_success(**return_args)
      end

      def failure(**return_args)
        on_failure(**return_args)
      end

      ## Must Define Callbacks In Subclass

      def on_success(**args)
        fail NotImplementedError
      end

      def on_failure(**args)
        fail NotImplementedError
      end


      private

      def context_has_errors?
        return unless respond_to?(:context) && context
        context.errors.present?
      end

      def execute!
        user_story.call(
          listener: self,
          on_success: :success,
          on_failure: :failure,
          **execution_args,
        )
      end

      def execution_args
        @execution_args ||= initial_resolve_args.merge(user_story_args)
      end

      def user_story
        class_name = self.class.user_story_class_name || fail(InvalidUserStory)
        class_name.constantize

      rescue NameError
        raise InvalidUserStory, "User story name '#{class_name}' did not constantize."
      end

      def user_story_args
        @user_story_args ||= begin
          args = self.class.user_story_args
          args.each_with_object({}) do |(name, options), user_story_args|
            user_story_argument_method_name = options[:method] || name
            user_story_args[name] = send user_story_argument_method_name
          end

        rescue NoMethodError => e
          raise InvalidUserStoryArgumentMethod, e.name
        end
      end

    end

  end

end
