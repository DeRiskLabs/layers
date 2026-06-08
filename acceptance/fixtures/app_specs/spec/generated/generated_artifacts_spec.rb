# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'generated artifacts' do
  describe 'unit generators' do
    it 'loads the generated use case' do
      expect(UseCases::Gadgets::Create).to be_a(Class)
    end

    it 'creates the use case spec' do
      expect(Rails.root.join('spec/lib/use_cases/gadgets/create_spec.rb')).to exist
    end

    it 'loads the generated user story' do
      expect(UserStories::Gadgets::Register).to be_a(Class)
    end

    it 'loads the generated query object' do
      expect(Queries::GadgetsQuery).to be_a(Class)
    end

    it 'loads a valid generated form' do
      expect(Forms::Gadgets::CreateForm.new.valid?).to be(true)
    end

    it 'builds the generated form on Layers::BaseForm' do
      expect(Forms::Gadgets::CreateForm.ancestors).to include(Layers::BaseForm)
    end

    it 'whitelists nothing by default' do
      expect(Forms::Gadgets::CreateForm.new.form_error_messages).to eq([])
    end
  end

  describe 'the component scaffold' do
    def billing
      $LOAD_PATH.unshift(Rails.root.join('components/billing/lib').to_s)
      require 'billing'
      Billing
    end

    it 'creates the gemspec' do
      expect(Rails.root.join('components/billing/billing.gemspec')).to exist
    end

    it 'declares the root constant' do
      expect(Rails.root.join('components/billing/lib/billing.rb').read).to include('module Billing')
    end

    it 'configures and resolves repositories' do
      billing.configure { |config| config.register_repository widget: 'Widget' }
      expect(billing.configuration.repo[:widget]).to be(Widget)
    end

    it 'forgets removed repositories' do
      billing.configure { |config| config.register_repository widget: 'Widget' }
      billing.configuration.repo.remove_repository(:widget)
      expect(billing.configuration.repo.registered?(:widget)).to be(false)
    end

    it 'creates an executable component isolation runner' do
      expect(Rails.root.join('bin/test_components')).to be_executable
    end
  end

  describe 'the graphql generators' do
    it 'declares the user story on the mutation' do
      mutation = Rails.root.join('apis/graph/app/graphql/graph/mutations/articles/create_article.rb')
      expect(mutation.read).to include("user_story 'user_stories/graph/articles/create_article'")
    end

    it 'creates the engine-local user story' do
      story = Rails.root.join('apis/graph/app/lib/user_stories/graph/articles/create_article.rb')
      expect(story).to exist
    end

    it 'registers the mutation' do
      expect(Rails.root.join('apis/graph/app/graphql/graph/types/mutation_type.rb').read)
        .to include('field :create_article, mutation: Graph::Mutations::Articles::CreateArticle')
    end

    it 'creates both resolvers' do
      ['articles', 'article'].each do |name|
        expect(Rails.root.join("apis/graph/app/graphql/graph/resolvers/articles/#{name}.rb")).to exist
      end
    end

    it 'registers both resolvers' do
      content = Rails.root.join('apis/graph/app/graphql/graph/types/query_type.rb').read
      expect(content).to include('field :articles, resolver: Graph::Resolvers::Articles::Articles')
        .and include('field :article, resolver: Graph::Resolvers::Articles::Article')
    end

    it 'creates the pending acceptance specs' do
      ['create_article', 'articles', 'article'].each do |name|
        expect(Rails.root.join("spec/acceptance/graph/articles/#{name}_spec.rb")).to exist
      end
    end
  end

  describe 'the engine generator' do
    it 'boots the feature engine' do
      expect(BillingPortal::Engine.ancestors).to include(Rails::Engine)
    end

    it 'loads the engine-local bases' do
      expect(UseCases::BillingPortal::BaseUseCase.ancestors).to include(Layers::BaseLayer)
      expect(UserStories::BillingPortal::BaseUserStory.ancestors).to include(Layers::BaseLayer)
    end

    it 'boots the api engine api_only' do
      expect(V2::Engine.config.api_only).to be(true)
    end

    it 'mounts both engines' do
      routes = Rails.root.join('config/routes.rb').read
      expect(routes).to include("mount BillingPortal::Engine, at: '/'")
        .and include("mount V2::Engine, at: '/v2'")
    end

    it 'consumes both engines via path blocks' do
      gemfile = Rails.root.join('Gemfile').read
      expect(gemfile).to include("path 'engines' do\n  gem 'billing_portal'")
        .and include("path 'apis' do\n  gem 'v2'")
    end

    it 'creates both container initializers' do
      expect(Rails.root.join('config/initializers/billing_portal.rb')).to exist
      expect(Rails.root.join('config/initializers/v2.rb')).to exist
    end

    it 'resolves container use cases through the engine registry' do
      BillingPortal.configure do |config|
        config.register_use_case create_widget: 'UseCases::Widgets::Create'
      end
      expect(BillingPortal.configuration.use_cases[:create_widget]).to be(UseCases::Widgets::Create)
    end

    it 'resolves container query objects through the engine registry' do
      V2.configure do |config|
        config.register_query_object gadgets: 'Queries::GadgetsQuery'
      end
      expect(V2.configuration.queries[:gadgets]).to be(Queries::GadgetsQuery)
    end
  end

  describe 'the api_endpoint scaffold' do
    it 'generates the container use case and form' do
      expect(UseCases::Orders::Create).to be_a(Class)
      expect(Forms::Orders::CreateForm.ancestors).to include(Layers::BaseForm)
    end

    it 'places the engine user story resolving the use case through the registry' do
      story = Rails.root.join('apis/v2/app/lib/user_stories/v2/orders/create.rb').read
      expect(story).to include('class Create < BaseUserStory')
        .and include('V2.configuration.use_cases[:orders_create]')
    end

    it 'places a controller that delegates to the engine story' do
      controller = Rails.root.join('apis/v2/app/controllers/v2/orders_controller.rb').read
      expect(controller).to include('class OrdersController < ApplicationController')
        .and include('UserStories::V2::Orders::Create.call')
    end

    it 'places a serializer' do
      serializer = Rails.root.join('apis/v2/app/serializers/v2/order_serializer.rb').read
      expect(serializer).to include('class OrderSerializer')
        .and include('include JSONAPI::Serializer')
    end

    it 'adds the route' do
      expect(Rails.root.join('apis/v2/config/routes.rb').read)
        .to include('resources :orders, only: %i[create], param: :uuid')
    end

    it 'registers the use case in the engine initializer' do
      expect(Rails.root.join('config/initializers/v2.rb').read)
        .to include("config.register_use_case orders_create: 'UseCases::Orders::Create'")
    end

    it 'creates pending request and routing specs' do
      expect(Rails.root.join('apis/v2/spec/requests/v2/orders_spec.rb')).to exist
      expect(Rails.root.join('apis/v2/spec/routing/v2/orders_routing_spec.rb')).to exist
    end
  end
end
