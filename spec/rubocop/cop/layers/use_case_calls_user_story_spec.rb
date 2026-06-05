# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/rubocop'

RSpec.describe RuboCop::Cop::Layers::UseCaseCallsUserStory do
  subject(:cop) { described_class.new(RuboCop::Config.new) }

  def offenses(source, path)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, path)
    team = RuboCop::Cop::Team.new([cop], RuboCop::Config.new, raise_error: true)
    team.investigate(processed).offenses
  end

  context 'with a user story reference inside a use case file' do
    it 'flags the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/app/lib/use_cases/create.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a top-level user story reference' do
    it 'flags the reference' do
      found = offenses('::UserStories::Widgets::Register.call', '/app/lib/use_cases/create.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a user story reference in a controller' do
    it 'allows the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/app/controllers/w_controller.rb')
      expect(found).to be_empty
    end
  end

  context 'with an unrelated constant in a use case file' do
    it 'allows the reference' do
      found = offenses('Forms::Widgets::CreateForm.new', '/app/lib/use_cases/create.rb')
      expect(found).to be_empty
    end
  end

  context 'with an offense' do
    it 'explains the direction rule' do
      found = offenses('UserStories::Register.call', '/app/lib/use_cases/create.rb')
      expect(found.first.message).to match(/never calls a user story/)
    end
  end
end
