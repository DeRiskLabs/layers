# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/rubocop'

RSpec.describe RuboCop::Cop::Layers::UserStoryOutsideAdapter do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  def offenses(source, path)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, path)
    team = RuboCop::Cop::Team.new([cop], config, raise_error: true)
    team.investigate(processed).offenses
  end

  context 'with a user story reference in a job' do
    it 'flags the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/app/jobs/digest_job.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a user story reference in a model' do
    it 'flags the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/app/models/widget.rb')
      expect(found.size).to eq(1)
    end
  end

  context 'with a user story reference in a controller' do
    it 'allows the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/app/controllers/w_controller.rb')
      expect(found).to be_empty
    end
  end

  context 'with a user story reference in a graphql endpoint' do
    it 'allows the reference' do
      found = offenses('UserStories::Widgets::Register', '/apis/graph/app/graphql/mutations/c.rb')
      expect(found).to be_empty
    end
  end

  context 'with a user story referencing another user story' do
    it 'allows the reference' do
      found = offenses('UserStories::Widgets::Base', '/app/lib/user_stories/widgets/register.rb')
      expect(found).to be_empty
    end
  end

  context 'with a user story reference in a spec' do
    it 'allows the reference' do
      found = offenses('UserStories::Widgets::Register.call', '/spec/lib/user_stories/r_spec.rb')
      expect(found).to be_empty
    end
  end

  context 'with custom allowed paths' do
    let(:config) do
      RuboCop::Config.new(
        'Layers/UserStoryOutsideAdapter' => { 'AllowedPaths' => ['/rake_adapters/'] },
      )
    end

    it 'honours the configuration' do
      found = offenses('UserStories::Widgets::Register.call', '/lib/rake_adapters/digest.rb')
      expect(found).to be_empty
    end
  end
end
