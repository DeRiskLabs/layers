# frozen_string_literal: true

module Layers
  module Graphql
    module BaseEndpoint
      class InvalidUserStory < Layers::Error; end
      class InvalidUserStoryArgumentMethod < Layers::Error
        def initialize(method_name)
          message = "A 'user_story_arg :#{method_name}' has been set, " \
            'however no method with this name has been defined.'
          super(message)
        end
      end

      WIRING_ERRORS = [InvalidUserStory, InvalidUserStoryArgumentMethod].freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

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
        raise e if wiring_error?(e)
        raise e if e.is_a?(execution_error_class)

        raise execution_error_class, client_facing_message(e)
      end


      def success(**return_args)
        on_success(**return_args)
      end

      def failure(**return_args)
        on_failure(**return_args)
      end


      def on_success(**args)
        fail NotImplementedError
      end

      def on_failure(**args)
        fail NotImplementedError
      end


      private

      def client_facing_message(error)
        return error.message if expose_error?(error)

        log_masked_error(error)
        Layers.configuration.masked_error_message
      end

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

      def execution_error_class
        Layers.configuration.graphql_execution_error ||
          fail(Layers::ConfigurationError,
               'No GraphQL execution error class is available. ' \
               'Set Layers.configuration.graphql_execution_error.')
      end

      def expose_error?(error)
        return true if Layers.configuration.reveal_masked_errors

        Layers.configuration.exposed_error_classes.any? { |klass| error.is_a?(klass) }
      end

      def log_masked_error(error)
        detail = ["#{self.class} masked #{error.class}: #{error.message}", *error.backtrace]
        logger.error detail.join("\n")
      end

      def logger
        @logger ||= Layers::Logger.logger
      end

      def user_story
        class_name = self.class.user_story_class_name || fail(InvalidUserStory)
        class_name.constantize

      rescue NameError
        raise InvalidUserStory, "User story name '#{class_name}' did not constantize."
      end

      def wiring_error?(error)
        WIRING_ERRORS.any? { |klass| error.is_a?(klass) }
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
