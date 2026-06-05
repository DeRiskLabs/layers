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
- `Layers::Graphql::BaseEndpoint` — declarative `user_story` /
  `user_story_arg` wiring from GraphQL mutations and resolvers to user
  stories, with `GraphQL::ExecutionError` wrapping
- `Layers::Adapters` — host-integration adapters configured through
  `Layers.configure`:
  - pagination adapters (`Kaminari`, `WillPaginate`) with automatic
    detection, so query objects never know the pagination gem's spelling
  - relation validation adapters (`ActiveRecord`, `DuckType`) so query
    objects construct safely whether or not ActiveRecord is loaded
  - an injectable GraphQL execution error class, detected from the
    graphql gem when present; using the GraphQL pieces with none
    available raises `Layers::ConfigurationError`
- `Layers::Instrumenter` and the `instrument` macro — declared instrumenter
  classes are inserted between a layer and its listener as a callback daisy
  chain; subclasses implement `instrument!(outcome)` with the subject, the
  outcome payload, and timing helpers available
- Rails generators (`layers:use_case`, `layers:user_story`,
  `layers:query_object`, `layers:form`) emitting layer objects with paired
  pending specs in house style, and `layers:component` scaffolding a bounded
  context as an unbuilt gem under `lib/` (gemspec, root constant with registry
  accessor, isolated spec scaffold, autoloader ignore) plus the
  `bin/test_components` isolation runner
- Boundary cops (`require: layers/rubocop`): `Layers/UseCaseCallsUserStory`
  and `Layers/UserStoryOutsideAdapter` enforce the direction rules
- `Layers::BaseJob` — jobs as thin boundaries: `use_case '...'` declares the
  behaviour, `perform(**args)` runs it with the job as listener, and the
  default `on_failure` raises `JobFailed` (messages extracted per the failure
  contract) so queue retry semantics engage
- `Layers::Registry` — boot-injected name→class registries for component
  boundaries: lazy constantize with memoization, pass-through for non-string
  entries, and a per-class `suffix` macro for `registry[:identity]`
  convenience
- `Layers::SkillsInstaller` and the `layers:sync_skills` task — copies every
  bundled `ai-derisk_*` skill collection gem into a chosen directory, one
  subdirectory per collection, replacing each on every run so the copies
  track the bundled versions
- `Layers::SkillsCloner` and the `layers:clone_skills` task — clones (or
  fast-forward pulls) the live `AI-derisk_*` skill repositories for teams
  that contribute skills back
- `Layers::Railtie` — loads the gem's rake tasks inside Rails applications
- the `emits` macro — declares the payload keys success/failure carry,
  enforced at both ends: emitted payloads must match exactly
  (`MissingDeclaredOutputs`/`UndeclaredOutputs`), and wired listener
  callbacks are verified against the declaration at construction through
  their keyword signatures (`Layers::ContractViolation`)
- `Layers.configure` and `Layers::Logger` — configurable logging with
  Rails-aware fallbacks
- Full RSpec suite covering every public contract

### Fixed

Latent defects carried over from the embedded application copy:

- `BaseQueryObject#initialize` called a misspelled `byuild_relation_defaults!`,
  breaking every query object construction
- `layers/graphql.rb` required nonexistent `endpoint_builder` files
- `Graphql::BaseEndpoint` referenced an undefined `InvalidUserStoryError`
  constant (the class is `InvalidUserStory`)
- `BaseLayer#result` silently dropped positional success/failure args (a
  `tap` over a non-destructive `merge`)
- `camelize` / `constantize` / `present?` were unavailable outside Rails: the
  gem now requires the ActiveSupport core extensions it relies on

### Changed

- `Graphql::BaseEndpoint` masks unexpected errors from API clients: the
  original class, message, and backtrace are logged, and the execution error
  carries only the configured `masked_error_message` (default
  `'Internal error'`). Errors of the execution error class pass through
  untouched; `exposed_error_classes` allowlists others;
  `reveal_masked_errors` restores full messages for development
- Gem wiring errors (`InvalidUserStory`, `InvalidUserStoryArgumentMethod`)
  raise as themselves instead of being converted to execution errors —
  GraphQL servers render clients a generic internal error while error
  tracking keeps the full source
- `Layers::Logger.logger` prefers `Rails.logger` whenever Rails provides one
  (production included) and falls back to a `$stdout` logger standalone — the
  old `log/layers.log` file logger crashed when the directory was missing

### Removed

- `Layers::Result` — the ask-style result-object pattern carried over from the
  embedded copy conflicts with the gem's message-passing design; outcomes
  travel only as `success`/`failure` listener callbacks
