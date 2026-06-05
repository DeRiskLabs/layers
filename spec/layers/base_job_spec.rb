# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::BaseJob do
  describe '.use_case' do
    context 'when called with a string' do
      subject(:job_class) do
        Class.new do
          include Layers::BaseJob
          use_case 'use_cases/widgets/create'
        end
      end

      it 'camelizes the use case class name' do
        expect(job_class.use_case_class_name).to eq('UseCases::Widgets::Create')
      end
    end

    context 'when called with a non-string' do
      it 'raises ArgumentError' do
        expect do
          Class.new do
            include Layers::BaseJob
            use_case :create_widget
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#perform' do
    subject(:job) { job_class.new }

    let(:use_case_class) { spy('UseCaseClass') }

    let(:job_class) do
      Class.new do
        include Layers::BaseJob
        use_case 'create_widget'
      end
    end

    before do
      stub_const('CreateWidget', use_case_class)
    end

    context 'with a declared use case' do
      execute do
        job.perform(widget_id: 1)
      end

      it 'calls the use case as listener with its callbacks' do
        expect(use_case_class).to have_received(:call)
          .with(listener: job, on_success: :success, on_failure: :failure, widget_id: 1)
      end
    end

    context 'when no use case is declared' do
      let(:job_class) { Class.new.include(described_class) }

      it 'raises InvalidUseCase' do
        expect do
          job.perform(widget_id: 1)
        end.to raise_error(described_class::InvalidUseCase)
      end
    end

    context 'when the use case does not constantize' do
      let(:job_class) do
        Class.new do
          include Layers::BaseJob
          use_case 'missing_use_case'
        end
      end

      it 'raises InvalidUseCase explaining the failure' do
        expect do
          job.perform(widget_id: 1)
        end.to raise_error(described_class::InvalidUseCase, /did not constantize/)
      end
    end
  end

  describe '#success' do
    subject(:job) { job_class.new }

    context 'with the default implementation' do
      let(:job_class) { Class.new.include(described_class) }

      it 'is a no-op' do
        expect(job.success(widget: :widget)).to be_nil
      end
    end

    context 'when the job defines on_success' do
      let(:probe) { spy('Probe') }

      let(:job_class) do
        Class.new do
          include Layers::BaseJob

          attr_accessor :probe

          def on_success(**args)
            probe.on_success(**args)
          end
        end
      end

      execute do
        job.probe = probe
        job.success(widget: :widget)
      end

      it 'forwards to on_success' do
        expect(probe).to have_received(:on_success).with(widget: :widget)
      end
    end
  end

  describe '#failure' do
    subject(:job) { job_class.new }

    let(:job_class) do
      Class.new do
        include Layers::BaseJob
        use_case 'create_widget'
      end
    end

    context 'with the default implementation' do
      it 'raises JobFailed naming the use case' do
        expect do
          job.failure(errors: ['boom'])
        end.to raise_error(described_class::JobFailed, /CreateWidget failed: boom/)
      end
    end

    context 'with an errors-bearing object in the payload' do
      let(:errors) { double('Errors', full_messages: ["Name can't be blank"]) }
      let(:form) { double('Form', errors: errors) }

      it 'extracts the error messages' do
        expect do
          job.failure(form: form)
        end.to raise_error(described_class::JobFailed, /Name can't be blank/)
      end
    end

    context 'with an empty payload' do
      it 'raises JobFailed without messages' do
        expect do
          job.failure
        end.to raise_error(described_class::JobFailed, /CreateWidget failed\z/)
      end
    end

    context 'when the job overrides on_failure' do
      let(:job_class) do
        Class.new do
          include Layers::BaseJob

          def on_failure(**_args)
            :discarded
          end
        end
      end

      it 'uses the override' do
        expect(job.failure(errors: ['boom'])).to be(:discarded)
      end
    end
  end
end
