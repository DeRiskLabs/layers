# frozen_string_literal: true

module Layers
  class Registry
    class NotRegistered < Layers::Error; end
    class InvalidEntry < Layers::Error; end

    class << self
      attr_reader :suffix_name

      def suffix(name)
        @suffix_name = name
      end
    end

    def initialize(entries = {})
      @entries = entries.transform_keys(&:to_sym)
      @resolved = {}
    end

    def [](name)
      key = registered_name(name)
      fail NotRegistered, "Nothing registered for '#{name}'." unless key

      @resolved[key] ||= resolve(key)
    end

    def registered?(name)
      !registered_name(name).nil?
    end

    def to_h
      entries.dup
    end

    def names
      entries.keys
    end


    private

    attr_reader :entries

    def registered_name(name)
      candidates(name).find { |candidate| entries.key?(candidate) }
    end

    def candidates(name)
      [name.to_sym, suffixed_name(name)].compact
    end

    def suffixed_name(name)
      suffix = self.class.suffix_name
      :"#{name}_#{suffix}" if suffix
    end

    def resolve(key)
      entry = entries[key]
      return entry unless entry.is_a?(String)

      entry.constantize
    rescue NameError
      raise InvalidEntry, "Entry '#{key}' ('#{entry}') did not constantize."
    end
  end
end
