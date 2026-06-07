# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/rubocop'

RSpec.describe RuboCop::Cop::Layers::SliceReferencesContainerLayer do
  subject(:cop) { described_class.new(RuboCop::Config.new) }

  def offenses(source, path)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, path)
    team = RuboCop::Cop::Team.new([cop], RuboCop::Config.new, raise_error: true)
    team.investigate(processed).offenses
  end

  context 'with a use case reference inside an engine file' do
    it 'flags the reference' do
      found = offenses('UseCases::Widgets::Create.call',
                       '/engines/billing/app/lib/user_stories/billing/create.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a query reference inside an api engine file' do
    it 'flags the reference' do
      found = offenses('Queries::WidgetsQuery.new',
                       '/apis/v1/app/lib/user_stories/v1/index.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a use case reference inside a component file' do
    it 'flags the reference' do
      found = offenses('UseCases::Things::Do.call', '/components/billing/lib/billing/thing.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a top-level use case reference inside a slice' do
    it 'flags the reference' do
      found = offenses('::UseCases::Widgets::Create.call', '/apis/v1/app/controllers/v1/w.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with the engine resolving through its registry' do
    it 'allows the reference' do
      found = offenses('Billing.configuration.use_cases[:create]',
                       '/engines/billing/app/lib/user_stories/billing/create.rb')
      expect(found).to be_empty
    end
  end

  context 'with an engine-owned user story reference inside a slice' do
    it 'allows the reference' do
      found = offenses('UserStories::Billing::Create.call',
                       '/engines/billing/app/controllers/billing/w.rb')
      expect(found).to be_empty
    end
  end

  context 'with a use case reference in the container' do
    it 'allows the reference' do
      found = offenses('UseCases::Widgets::Create.call', '/app/lib/user_stories/widgets/create.rb')
      expect(found).to be_empty
    end
  end

  context 'with a use case module definition inside the container' do
    it 'allows the definition' do
      found = offenses("module UseCases\n  module Widgets\n  end\nend",
                       '/app/lib/use_cases/widgets/create.rb')
      expect(found).to be_empty
    end
  end
end
