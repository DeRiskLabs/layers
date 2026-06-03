# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Graphql::BaseEndpoint do
  describe 'Class Methods' do
    subject(:test_class) { Class.new.include(described_class) }

    it { is_expected.to respond_to(:user_story) }
    it { is_expected.to respond_to(:user_story_class_name) }
    it { is_expected.to respond_to(:user_story_arg) }
    it { is_expected.to respond_to(:user_story_args) }

    describe '.user_story' do
      context 'when called with a string' do
        subject(:test_class) do
          Class.new do
            include Layers::Graphql::BaseEndpoint
            user_story 'user_stories/create_widget'
          end
        end

        it 'camelizes the user story class name' do
          expect(test_class.user_story_class_name).to eq('UserStories::CreateWidget')
        end
      end

      context 'when called with a non-string' do
        it 'raises ArgumentError' do
          expect do
            Class.new do
              include Layers::Graphql::BaseEndpoint
              user_story :create_widget
            end
          end.to raise_error(ArgumentError)
        end
      end
    end

    describe '.user_story_arg' do
      subject(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story_arg :widget, method: :build_widget
        end
      end

      it 'registers the argument with its options' do
        expect(test_class.user_story_args).to eq({ widget: { method: :build_widget } })
      end
    end
  end

  describe '#resolve' do
    subject(:endpoint) { test_class.new }

    let(:user_story_class) { spy('UserStoryClass') }

    let(:test_class) do
      Class.new do
        include Layers::Graphql::BaseEndpoint
        user_story 'create_widget'
      end
    end

    before do
      stub_const('CreateWidget', user_story_class)
      stub_const('GraphQL::ExecutionError', Class.new(StandardError))
    end

    context 'with a declared user story' do
      execute do
        endpoint.resolve(id: 1)
      end

      it 'stores the resolve args' do
        expect(endpoint.initial_resolve_args).to eq({ id: 1 })
      end

      it 'calls the user story as listener with its callbacks' do
        expect(user_story_class).to have_received(:call)
          .with(listener: endpoint, on_success: :success, on_failure: :failure, id: 1)
      end
    end

    context 'with a user story arg' do
      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story 'create_widget'
          user_story_arg :widget

          def widget
            { name: 'sprocket' }
          end
        end
      end

      execute do
        endpoint.resolve(id: 1)
      end

      it 'resolves the argument through its method' do
        expect(user_story_class).to have_received(:call)
          .with(hash_including(widget: { name: 'sprocket' }))
      end
    end

    context 'with an aliased user story arg' do
      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story 'create_widget'
          user_story_arg :widget, method: :build_widget

          def build_widget
            :built
          end
        end
      end

      execute do
        endpoint.resolve(id: 1)
      end

      it 'resolves the argument through the aliased method' do
        expect(user_story_class).to have_received(:call)
          .with(hash_including(widget: :built))
      end
    end

    context 'when the context has errors' do
      subject(:endpoint) { test_class.new(context) }

      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story 'create_widget'

          attr_reader :context

          def initialize(context)
            @context = context
          end
        end
      end

      let(:context) { double('Context', errors: errors) }
      let(:errors) { double('Errors', present?: true) }

      execute do
        endpoint.resolve(id: 1)
      end

      it 'does not call the user story' do
        expect(user_story_class).not_to have_received(:call)
      end
    end

    context 'when no user story is declared' do
      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
        end
      end

      it 'raises ExecutionError' do
        expect do
          endpoint.resolve(id: 1)
        end.to raise_error(GraphQL::ExecutionError)
      end
    end

    context 'when the user story does not constantize' do
      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story 'missing_widget'
        end
      end

      it 'raises ExecutionError explaining the failure' do
        expect do
          endpoint.resolve(id: 1)
        end.to raise_error(GraphQL::ExecutionError, /did not constantize/)
      end
    end

    context 'when a user story arg method is missing' do
      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint
          user_story 'create_widget'
          user_story_arg :widget
        end
      end

      it 'raises ExecutionError naming the missing method' do
        expect do
          endpoint.resolve(id: 1)
        end.to raise_error(GraphQL::ExecutionError, /user_story_arg :widget/)
      end
    end

    context 'when the user story raises' do
      before do
        allow(user_story_class).to receive(:call).and_raise(StandardError, 'boom')
      end

      it 'wraps the error in ExecutionError' do
        expect do
          endpoint.resolve(id: 1)
        end.to raise_error(GraphQL::ExecutionError, 'boom')
      end
    end
  end

  describe '#success' do
    context 'when the subclass defines on_success' do
      subject(:endpoint) { test_class.new(probe) }

      let(:probe) { spy('Probe') }

      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint

          attr_reader :probe

          def initialize(probe)
            @probe = probe
          end

          def on_success(**args)
            probe.on_success(**args)
          end
        end
      end

      execute do
        endpoint.success(widget: 'sprocket')
      end

      it 'forwards to on_success' do
        expect(probe).to have_received(:on_success).with(widget: 'sprocket')
      end
    end

    context 'when the subclass does not define on_success' do
      subject(:endpoint) { test_class.new }

      let(:test_class) { Class.new.include(described_class) }

      it 'raises NotImplementedError' do
        expect do
          endpoint.success
        end.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#failure' do
    context 'when the subclass defines on_failure' do
      subject(:endpoint) { test_class.new(probe) }

      let(:probe) { spy('Probe') }

      let(:test_class) do
        Class.new do
          include Layers::Graphql::BaseEndpoint

          attr_reader :probe

          def initialize(probe)
            @probe = probe
          end

          def on_failure(**args)
            probe.on_failure(**args)
          end
        end
      end

      execute do
        endpoint.failure(error: 'boom')
      end

      it 'forwards to on_failure' do
        expect(probe).to have_received(:on_failure).with(error: 'boom')
      end
    end

    context 'when the subclass does not define on_failure' do
      subject(:endpoint) { test_class.new }

      let(:test_class) { Class.new.include(described_class) }

      it 'raises NotImplementedError' do
        expect do
          endpoint.failure
        end.to raise_error(NotImplementedError)
      end
    end
  end
end
