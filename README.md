# Layers

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

A Ruby gem for building clean, maintainable applications using a layered architecture.
Layers helps you separate business logic from framework code using message-passing and
clear boundaries.

## Overview

Layers provides a structured way to organize Ruby applications following clean
architecture principles:

- **Clear boundaries**: separate your application into distinct layers with well-defined
  responsibilities
- **Message passing**: layers report outcomes by calling back a listener with a
  consistent success/failure protocol, instead of returning values for callers to
  interpret
- **Framework independence**: business logic stays free of framework dependencies, so
  the same object serves REST controllers, GraphQL endpoints, background jobs, and tests
  unchanged
- **Testability**: every layer is a plain Ruby object with declared inputs and
  observable outcomes

The gem provides three building blocks:

| Class | Purpose |
| --- | --- |
| `Layers::BaseLayer` | Base class for use cases, user stories, and other business operations |
| `Layers::BaseQueryObject` | Base class for scoped, chainable read objects |
| `Layers::Graphql::BaseEndpoint` | Declarative GraphQL mutation/resolver integration |

## Requirements

- Ruby >= 3.1
- `activesupport` >= 7.0 and `naught` (installed automatically)
- An ActiveRecord-compatible relation if you use `Layers::BaseQueryObject`
- The `graphql` gem if you use `Layers::Graphql::BaseEndpoint`

## Installation

The gem is distributed from a private git source. Add to your Gemfile:

```ruby
gem 'layers', git: 'git@github.com:richardjordan/layers.git', tag: 'v1.0.0'
```

Then run:

```bash
$ bundle install
```

## Core Concepts

### The layer lifecycle

Every layer object follows the same lifecycle:

1. **Instantiate** with declared inputs (and optionally a listener and callbacks)
2. **Execute** business logic in `#call`
3. **Report** the outcome with `success(...)` or `failure(...)`, which notifies
   observers and calls the listener back

Because `Layers::DSL::ClassCallable` is included, the whole lifecycle is one call:

```ruby
UseCases::Members::CreateSeller.call(identity: identity)
```

is equivalent to `UseCases::Members::CreateSeller.new(identity: identity).call`.

### The message protocol

Inside `#call`, report the outcome — do not return it:

- `success(**args)` — marks the layer succeeded, notifies success observers, then calls
  the success callback on the listener with `args`
- `failure(**args)` — marks the layer failed, notifies failure observers, then calls
  the failure callback on the listener with `args`

After execution the layer also answers `success?`, `failure?`, and exposes the reported
args as `result`.

### Recommended base classes

Applications normally define their own base classes over the gem, one per layer type:

```ruby
class BaseUseCase < Layers::BaseLayer
end

class BaseUserStory < Layers::BaseLayer
end
```

- **Use cases** (`UseCases::*`) perform a single transactional write
- **User stories** (`UserStories::*`) orchestrate a user-facing action: they coordinate
  use cases, forms, and query objects

## Defining a Layer

### Declaring inputs

Declare what the layer needs with the inputs DSL. Each declaration creates an accessor:

```ruby
class UseCases::Members::CreateSeller < BaseUseCase
  required :identity                       # must be provided
  optional :referrer                       # may be provided
  optional_with_default role: :seller      # defaults when not provided
end
```

Input validation happens at construction:

- a missing required input raises `Layers::DSL::MissingRequiredInputs`
- an undeclared input raises `Layers::DSL::UnexpectedInputs`

Instances expose `inputs` (the raw hash), and `attributes`, `required_attributes`, and
`optional_attributes` (declared inputs with their current values).

### Implementing #call

`#call` holds the business logic and reports through the message protocol:

```ruby
module UseCases
  module Members
    class CreateSeller < BaseUseCase
      required :identity

      def call
        return failure(seller: identity) unless create_seller

        success(seller: identity)

      rescue ActiveRecord::RecordInvalid => e
        log_failure(e)
      end

      private

      def create_seller
        ActiveRecord::Base.transaction do
          business = Business.create!(owner: identity)

          Auth.grant_role identity, role: :seller
          Auth.grant_role identity, role: :owner, on: business
        end
      end

      def log_failure(e)
        Rails.logger.error "Failed to create Seller for identity '#{identity.uuid}': #{e.message}"
        failure(seller: identity)
      end
    end
  end
end
```

A layer that does not implement `#call` raises `NotImplementedError` when called.

### Listeners and callbacks

The caller passes itself as the listener; the layer calls back on success or failure:

```ruby
UseCases::Members::CreateSeller.call(
  identity: identity,
  listener: self,
  on_success: :create_succeeded,
  on_failure: :create_failed,
)
```

- `listener:` — the object to call back (defaults to a null listener that silently
  swallows every message, so layers can run fire-and-forget)
- `on_success:` / `on_failure:` — the listener methods to call (default to `:on_success`
  and `:on_failure`)

A class can change its own callback defaults:

```ruby
class BaseUseCase < Layers::BaseLayer
  default_callbacks on_failure: :use_case_failed,
                    on_success: :use_case_succeeded
end
```

### Observers

Observers handle side effects of an outcome without coupling the layer to them.
Register instance methods (or callables) per event; they run before the listener
callback:

```ruby
module UserStories
  module Members
    class Register < BaseUserStory
      required :registration
      observer :build_business_relationships, of_event: :success

      delegate :email, :identity, :interests, :email_address,
               :password, :password_confirmation, :user_account,
               to: :registration

      def call
        return failure(registration: registration) unless valid?

        email_address.identity = identity
        email_address.acts_as_primary = true
        user_account.identity = identity

        return fail_with_object_errors unless persist

        success(registration: registration)
      end

      private

      def persist
        ActiveRecord::Base.transaction do
          identity.save!
          email_address.save!
          user_account.save!
        end
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def build_business_relationships
        UseCases::Members::CreateAdvisor.call(identity: identity) if advisor?
        UseCases::Members::CreateSeller.call(identity: identity) if seller?
      end

      def advisor?
        interests.include?('advisor')
      end

      def seller?
        interests.include?('seller')
      end
    end
  end
end
```

`observer` defaults to `of_event: :success`; use `of_event: :failure` for failure-side
effects. An exception raised by an observer never breaks the layer: it is logged (see
[Configuration and Logging](#configuration-and-logging)), and you can register a handler
for it:

```ruby
observer_exception_handler :handle_observer_error
```

### Controller integration

The listener pattern keeps controllers thin — they translate HTTP and render:

```ruby
module Members
  class RegistrationsController < ApplicationController
    def create
      UserStories::Members::Register.call(
        registration: registration,
        listener: self,
        on_success: :create_succeeded,
        on_failure: :create_failed,
      )
    end

    def create_succeeded(registration:)
      session[:user_account_id] = registration.user_account.signed_id(
        purpose: :auth,
        expires_in: 12.hours,
      )
      flash[:success] = I18n.t('members.registrations.success')
      redirect_to dashboard_path
    end

    def create_failed(registration: nil, error: nil)
      flash[:alert] = error_messages_for_failed(registration)
      redirect_to signup_path
    end
  end
end
```

## Query Objects

`Layers::BaseQueryObject` extracts reads from models into scoped, chainable objects.
Subclasses declare their model and build their default scope:

```ruby
module Queries
  class ArticlesQuery < Layers::BaseQueryObject
    relation_class :article

    private

    def build_relation_defaults!
      @relation = relation.where(published: true)
    end
  end
end
```

- `relation_class` names the model that provides the initial relation. It takes a
  symbol/string (camelized and constantized) or a callable returning the class name; a
  name that does not constantize raises `Layers::QueryBuilder::ConfigurationError`.
- `build_relation_defaults!` is the subclass contract: apply the query's default
  scoping there. The base class raises `NotImplementedError` without it.

Construct with an explicit relation, a `relation:` option, or nothing (falls back to
the declared `relation_class`):

```ruby
Queries::ArticlesQuery.new                            # Article scoped by the defaults
Queries::ArticlesQuery.new(current_user.articles)     # an explicit starting relation
Queries::ArticlesQuery.new(relation: some_relation)   # option form (wins over the argument)
```

A relation must be an `ActiveRecord::Relation` or a model class; anything else raises
`Layers::BaseQueryObject::RelationError`. The original relation stays available as
`unscoped_relation`.

### Reading and chaining

Common read messages (`all`, `count`, `find`, `find_by`, `first`, `where`, `pluck`,
`includes`, `joins`, and friends) are delegated straight to the relation. Refining
methods mutate the internal relation and return the query itself, so they chain:

```ruby
query = Queries::ArticlesQuery.new
query.order(sort_field: :title, sort_direction: :asc).page(2).per(25).all
```

- `order(sort_field: :created_at, sort_direction: :desc)` — defaults shown
- `page(n)` then `per(size)` — pagination. Calling `per` before `page` raises
  `Layers::QueryBuilder::PaginationError`.

Pagination goes through an adapter, so the query object never knows which pagination
gem the host app uses. Kaminari is detected automatically; otherwise the will_paginate
message style (`page`/`per_page`) is used. Any object answering
`page(relation, number)` and `per(relation, size)` can be configured instead:

```ruby
Layers.configure do |config|
  config.pagination_adapter = Layers::Adapters::Pagination::Kaminari
end
```

Relation validation is also adapter-based. The default accepts `ActiveRecord::Relation`
instances and model classes; swap in `Layers::Adapters::Relation::DuckType` (anything
answering `where`) or your own `relation?(object)` predicate:

```ruby
Layers.configure do |config|
  config.relation_adapter = Layers::Adapters::Relation::DuckType
end
```

## GraphQL Endpoints

`Layers::Graphql::BaseEndpoint` connects GraphQL mutations and resolvers to user
stories declaratively. Include it in your GraphQL base class:

```ruby
module Graph
  class BaseMutation < GraphQL::Schema::Mutation
    include Layers::Graphql::BaseEndpoint
  end
end
```

Then a mutation names its user story, maps its arguments, and renders the callbacks:

```ruby
module Graph
  module Mutations
    class RegisterMember < BaseMutation
      user_story 'user_stories/members/register'
      user_story_arg :registration, method: :build_registration

      argument :email, String, required: true

      field :member, Types::MemberType, null: true
      field :errors, [String], null: false

      def on_success(registration:)
        { member: registration.identity, errors: [] }
      end

      def on_failure(registration: nil, error: nil)
        { member: nil, errors: Array(error) }
      end

      private

      def build_registration
        Registration.new(initial_resolve_args)
      end
    end
  end
end
```

How `resolve` works:

1. If the GraphQL `context` already has errors, it returns without running anything.
2. The resolver's arguments are captured as `initial_resolve_args`.
3. Each `user_story_arg` is resolved by calling the named method (`method:` option) or
   a method matching the arg name, and merged over the resolve args.
4. The user story is called with the endpoint as listener
   (`on_success: :success, on_failure: :failure`), which dispatches to your
   `on_success`/`on_failure` methods.
5. Any unexpected error is **masked from the client**: its class, message, and
   backtrace are logged through the gem's logger, and the configured GraphQL execution
   error class is raised carrying only `masked_error_message` (default
   `'Internal error'`). `GraphQL::ExecutionError` is detected automatically when the
   graphql gem is present, or inject your own:

   ```ruby
   Layers.configure do |config|
     config.graphql_execution_error = MyApp::ApiError
   end
   ```

   Using the GraphQL pieces with no error class available raises
   `Layers::ConfigurationError`.

What the client sees is controllable:

- Errors that are already the execution error class pass through untouched — they are
  client-facing by definition.
- `config.exposed_error_classes = [Widgets::NotAvailable]` allowlists domain errors
  whose messages are safe to expose.
- `config.reveal_masked_errors = Rails.env.local?` restores full messages while
  developing; the original error is always in the logs either way.

Configuration mistakes fail loudly for the developer: a missing or non-constantizable
`user_story` raises `InvalidUserStory`; a `user_story_arg` without a backing method
raises `InvalidUserStoryArgumentMethod`. These wiring errors are never converted to
execution errors — they raise as themselves, landing in your logs and error tracking
with full detail, while the GraphQL server shows clients its own generic internal
error. Endpoints that do not define `on_success`/`on_failure` raise
`NotImplementedError`.

## Configuration and Logging

`Layers.configure` is the single place the gem learns about its host:

```ruby
Layers.configure do |config|
  config.logger = SemanticLogger['layers']
  config.pagination_adapter = Layers::Adapters::Pagination::Kaminari
  config.relation_adapter = Layers::Adapters::Relation::DuckType
  config.graphql_execution_error = GraphQL::ExecutionError
  config.masked_error_message = 'Something went wrong'
  config.exposed_error_classes = [MyApp::ClientSafeError]
  config.reveal_masked_errors = Rails.env.local?
end
```

Every setting has a sensible default — a Rails app with kaminari or will_paginate and
graphql-ruby needs no configuration at all.

The gem logs through `Layers::Logger.logger`, which resolves in order:

1. The configured logger
2. `Rails.logger`, whenever Rails provides one (production included)
3. Its own `$stdout` logger

## Best Practices

### Layer organization

1. Keep layers focused and single-purpose
2. Use user stories for framework integration and orchestration
3. Put core business logic in use cases
4. Use observers for side effects

### Error handling

1. Use the failure/success protocol consistently
2. Include meaningful error messages
3. Log errors appropriately
4. Handle all error cases explicitly

### Testing

1. Test each layer in isolation
2. Mock dependencies in unit tests
3. Write integration tests for user stories
4. Test both success and failure paths

## Error Reference

| Error | Raised when |
| --- | --- |
| `Layers::Error` | Base class for all gem errors (`< StandardError`) |
| `Layers::ConfigurationError` | A required host integration is neither detected nor configured (e.g. no GraphQL execution error class) |
| `Layers::DSL::MissingRequiredInputs` | A required input was not provided (`< ArgumentError`) |
| `Layers::DSL::UnexpectedInputs` | An undeclared input was provided (`< ArgumentError`) |
| `Layers::DSL::ClassCallable::MissingMethodError` | `.call` hit a `TypeError` caused by a missing method — usually a broken delegation |
| `Layers::BaseQueryObject::RelationError` | A query object was built with something that is not a relation or model class |
| `Layers::QueryBuilder::ConfigurationError` | `relation_class` did not constantize to a model |
| `Layers::QueryBuilder::PaginationError` | `per` was called before `page` |
| `Layers::Graphql::BaseEndpoint::InvalidUserStory` | No `user_story` declared, or it did not constantize |
| `Layers::Graphql::BaseEndpoint::InvalidUserStoryArgumentMethod` | A `user_story_arg` has no backing method |

## Development

After checking out the repo:

```bash
$ bin/setup
$ bundle exec rspec
```

Before cutting a release, run the consumer smoke test. It generates a throwaway
API-only Rails app, installs the gem from this repository as a git source (committed
HEAD only — uncommitted changes are invisible to it), builds a small layer stack the
way a host app would (`app/lib/use_cases`, `app/lib/user_stories`, `app/lib/queries`,
a controller as listener), and exercises everything directly and over HTTP:

```bash
$ bin/smoke_test
```

## License

This project is licensed under the MIT License — see [LICENSE.txt](LICENSE.txt) for
details.
