# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'generated artifacts' do
  def read(relative)
    Rails.root.join(relative).read
  end

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
    let(:billing) do
      $LOAD_PATH.unshift(Rails.root.join('components/billing/lib').to_s)
      require 'billing'
      Billing
    end

    it 'creates the gemspec' do
      expect(Rails.root.join('components/billing/billing.gemspec')).to exist
    end

    it 'declares the root constant' do
      expect(read('components/billing/lib/billing.rb')).to include('module Billing')
    end

    it 'creates an executable component isolation runner' do
      expect(Rails.root.join('bin/test_components')).to be_executable
    end

    context 'with a registered repository' do
      before { billing.configure { |config| config.register_repository widget: 'Widget' } }

      it 'resolves the repository' do
        expect(billing.configuration.repo[:widget]).to be(Widget)
      end

      context 'when the repository is removed' do
        execute do
          billing.configuration.repo.remove_repository(:widget)
        end

        it 'forgets it' do
          expect(billing.configuration.repo.registered?(:widget)).to be(false)
        end
      end
    end
  end

  describe 'the graphql generators' do
    it 'declares the user story on the mutation' do
      expect(read('apis/graph/app/graphql/graph/mutations/articles/create_article.rb'))
        .to include("user_story 'user_stories/graph/articles/create_article'")
    end

    it 'creates the engine-local user story' do
      expect(Rails.root.join('apis/graph/app/lib/user_stories/graph/articles/create_article.rb'))
        .to exist
    end

    it 'registers the mutation' do
      expect(read('apis/graph/app/graphql/graph/types/mutation_type.rb'))
        .to include('field :create_article, mutation: Graph::Mutations::Articles::CreateArticle')
    end

    it 'creates the list resolver' do
      expect(Rails.root.join('apis/graph/app/graphql/graph/resolvers/articles/articles.rb'))
        .to exist
    end

    it 'creates the single resolver' do
      expect(Rails.root.join('apis/graph/app/graphql/graph/resolvers/articles/article.rb'))
        .to exist
    end

    it 'registers both resolvers' do
      expect(read('apis/graph/app/graphql/graph/types/query_type.rb'))
        .to include('field :articles, resolver: Graph::Resolvers::Articles::Articles')
        .and include('field :article, resolver: Graph::Resolvers::Articles::Article')
    end
  end

  describe 'the engine generator' do
    it 'boots the feature engine' do
      expect(BillingPortal::Engine.ancestors).to include(Rails::Engine)
    end

    it 'loads the engine-local use case base' do
      expect(UseCases::BillingPortal::BaseUseCase.ancestors).to include(Layers::BaseLayer)
    end

    it 'loads the engine-local user story base' do
      expect(UserStories::BillingPortal::BaseUserStory.ancestors).to include(Layers::BaseLayer)
    end

    it 'boots the api engine api_only' do
      expect(V2::Engine.config.api_only).to be(true)
    end

    it 'mounts both engines' do
      expect(read('config/routes.rb'))
        .to include("mount BillingPortal::Engine, at: '/'")
        .and include("mount V2::Engine, at: '/v2'")
    end

    it 'consumes both engines via path blocks' do
      expect(read('Gemfile'))
        .to include("path 'engines' do\n  gem 'billing_portal'")
        .and include("path 'apis' do\n  gem 'v2'")
    end

    it 'creates the feature engine initializer' do
      expect(Rails.root.join('config/initializers/billing_portal.rb')).to exist
    end

    it 'creates the api engine initializer' do
      expect(Rails.root.join('config/initializers/v2.rb')).to exist
    end

    context 'with a use case registered on the feature engine' do
      before do
        BillingPortal.configure do |config|
          config.register_use_case create_widget: 'UseCases::Widgets::Create'
        end
      end

      it 'resolves it through the registry' do
        expect(BillingPortal.configuration.use_cases[:create_widget]).to be(UseCases::Widgets::Create)
      end
    end

    context 'with a query object registered on the api engine' do
      before do
        V2.configure { |config| config.register_query_object gadgets: 'Queries::GadgetsQuery' }
      end

      it 'resolves it through the registry' do
        expect(V2.configuration.queries[:gadgets]).to be(Queries::GadgetsQuery)
      end
    end
  end

  describe 'the api_endpoint scaffold' do
    it 'generates the container use case' do
      expect(UseCases::Orders::Create).to be_a(Class)
    end

    it 'generates the container form on Layers::BaseForm' do
      expect(Forms::Orders::CreateForm.ancestors).to include(Layers::BaseForm)
    end

    it 'places the engine user story resolving the use case through the registry' do
      expect(read('apis/v2/app/lib/user_stories/v2/orders/create.rb'))
        .to include('class Create < BaseUserStory')
        .and include('V2.configuration.use_cases[:orders_create]')
    end

    it 'places a controller that delegates to the engine story' do
      expect(read('apis/v2/app/controllers/v2/orders_controller.rb'))
        .to include('class OrdersController < ApplicationController')
        .and include('UserStories::V2::Orders::Create.call')
    end

    it 'places a serializer' do
      expect(read('apis/v2/app/serializers/v2/order_serializer.rb'))
        .to include('class OrderSerializer')
        .and include('include JSONAPI::Serializer')
    end

    it 'adds the route' do
      expect(read('apis/v2/config/routes.rb'))
        .to include('resources :orders, only: %i[create], param: :uuid')
    end

    it 'registers the use case in the engine initializer' do
      expect(read('config/initializers/v2.rb'))
        .to include("config.register_use_case orders_create: 'UseCases::Orders::Create'")
    end

    it 'creates the pending request spec' do
      expect(Rails.root.join('apis/v2/spec/requests/v2/orders_spec.rb')).to exist
    end

    it 'creates the pending routing spec' do
      expect(Rails.root.join('apis/v2/spec/routing/v2/orders_routing_spec.rb')).to exist
    end
  end
end
