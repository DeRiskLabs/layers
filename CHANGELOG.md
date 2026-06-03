# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-03

First standalone release. The gem was previously maintained as an unbuilt copy
embedded in applications (`lib/layers`); this release packages it for
distribution from a private git source.

### Added

- `Layers::BaseLayer` — base class for use cases and user stories, composed from
  the DSL mixins:
  - `Layers::DSL::Inputs` — `required` / `optional` / `optional_with_default`
    input declarations with construction-time validation
  - `Layers::DSL::Observers` — `observer ... of_event:` side-effect registration
    with exception isolation and `observer_exception_handler`
  - `Layers::DSL::NullListener` — fire-and-forget default listener
  - `Layers::DSL::CallbackDefaults` — `default_callbacks` with per-class
    overrides
  - `Layers::DSL::ClassCallable` — `.call` convenience with
    `MissingMethodError` diagnostics for delegation-caused `TypeError`s
- `Layers::BaseQueryObject` — scoped, chainable query objects with
  `relation_class` defaults, relation validation, delegated read messages, and
  the `QueryBuilder` mixins (`RelationDefaults`, `Paginate`, `Sort`)
- `Layers::Result` — success/failure value object with error normalization,
  `and_then` chaining, and `on_success` / `on_failure` taps
- `Layers::Graphql::BaseEndpoint` — declarative `user_story` /
  `user_story_arg` wiring from GraphQL mutations and resolvers to user
  stories, with `GraphQL::ExecutionError` wrapping
- `Layers.configure` and `Layers::Logger` — configurable logging with
  Rails-aware fallbacks
- Full RSpec suite (189 examples) covering every public contract

### Fixed

Latent defects carried over from the embedded application copy:

- `BaseQueryObject#initialize` called a misspelled `byuild_relation_defaults!`,
  breaking every query object construction
- `layers/graphql.rb` required nonexistent `endpoint_builder` files
- `Graphql::BaseEndpoint` referenced an undefined `InvalidUserStoryError`
  constant (the class is `InvalidUserStory`)
- `Layers::Result` was never required, making the class unreachable for
  consumers of `require 'layers'`
- `camelize` / `constantize` / `present?` were unavailable outside Rails: the
  gem now requires the ActiveSupport core extensions it relies on
