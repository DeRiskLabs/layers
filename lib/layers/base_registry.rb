# frozen_string_literal: true

module Layers
  class BaseRegistry
    class NotRegistered < Layers::Error; end
    class InvalidEntry < Layers::Error; end

    def initialize(**entries)
      register(**entries)
    end

    def [](name)
      resolve(name.to_sym)
    end

    def register(**entries)
      entries.each { |name, entry| store[name.to_sym] = entry.to_s }
    end

    def remove(name)
      store.delete(name.to_sym)
    end

    def registered
      store.keys
    end

    def registered?(name)
      store.key?(name.to_sym)
    end

    def to_h
      store.dup
    end


    private

    def store
      @store ||= defaults.to_h { |name, entry| [name.to_sym, entry.to_s] }
    end

    def defaults
      {}
    end

    def resolve(key)
      entry = store[key] || fail(NotRegistered, "Nothing registered for ':#{key}'.")
      entry.constantize
    rescue NameError
      raise InvalidEntry, "Entry ':#{key}' ('#{entry}') did not constantize."
    end
  end
end
