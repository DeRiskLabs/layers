# frozen_string_literal: true

module Layers
  module DSL
    module Emits
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def emits(success: nil, failure: nil)
          @emitted_success_keys = Set.new(success) if success
          @emitted_failure_keys = Set.new(failure) if failure
        end

        def emitted_success_keys
          @emitted_success_keys
        end

        def emitted_failure_keys
          @emitted_failure_keys
        end
      end


      private

      def validate_emitted!(outcome, opts)
        declared = declared_keys_for(outcome)
        return unless declared

        missing = declared.reject { |key| opts.key?(key) }
        unless missing.empty?
          fail MissingDeclaredOutputs,
               "#{self.class} did not emit declared #{outcome} keys: #{missing.join(', ')}"
        end

        extra = opts.keys.reject { |key| declared.include?(key) }
        return if extra.empty?

        fail UndeclaredOutputs,
             "#{self.class} emitted undeclared #{outcome} keys: #{extra.join(', ')}"
      end

      def verify_listener_contract!
        verify_callback!(:success, on_success)
        verify_callback!(:failure, on_failure)
      end

      def verify_callback!(outcome, callback_name)
        declared = declared_keys_for(outcome)
        return unless declared

        parameters = callback_parameters(callback_name)
        return unless parameters
        return unless keyword_aware?(parameters)

        verify_required_keywords!(outcome, callback_name, declared, parameters)
        verify_receivable_keys!(outcome, callback_name, declared, parameters)
      end

      def verify_required_keywords!(outcome, callback_name, declared, parameters)
        excess = required_keywords(parameters).reject { |key| declared.include?(key) }
        return if excess.empty?

        fail Layers::ContractViolation,
             "#{listener.class}##{callback_name} requires keywords never emitted " \
             "by #{self.class} for #{outcome}: #{excess.join(', ')}"
      end

      def verify_receivable_keys!(outcome, callback_name, declared, parameters)
        return if keyrest?(parameters)

        unreceivable = declared.reject { |key| accepted_keywords(parameters).include?(key) }
        return if unreceivable.empty?

        fail Layers::ContractViolation,
             "#{listener.class}##{callback_name} cannot receive #{outcome} keys " \
             "emitted by #{self.class}: #{unreceivable.join(', ')}"
      end

      def callback_parameters(callback_name)
        method = listener.method(callback_name)
        Method.instance_method(:parameters).bind_call(method)
      rescue ::NameError, ::TypeError
        nil
      end

      def keyword_aware?(parameters)
        parameters.any? { |type, _name| [:key, :keyreq, :keyrest].include?(type) }
      end

      def required_keywords(parameters)
        parameters.select { |type, _name| type == :keyreq }.map { |_type, name| name }
      end

      def accepted_keywords(parameters)
        parameters.select { |type, _name| [:key, :keyreq].include?(type) }
                  .map { |_type, name| name }
      end

      def keyrest?(parameters)
        parameters.any? { |type, _name| type == :keyrest }
      end

      def declared_keys_for(outcome)
        if outcome == :success
          self.class.emitted_success_keys
        else
          self.class.emitted_failure_keys
        end
      end
    end
  end
end
