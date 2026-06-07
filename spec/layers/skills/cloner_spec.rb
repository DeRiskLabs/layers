# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/skills/installer'
require 'layers/skills/cloner'
require 'tmpdir'

RSpec.describe Layers::Skills::Cloner do
  subject(:cloner) do
    described_class.new(target_dir: target_dir, base_url: base_url, runner: runner)
  end

  let(:workspace) { Dir.mktmpdir }
  let(:target_dir) { File.join(workspace, 'skills') }
  let(:base_url) { 'https://github.com/DeriskLabs' }
  let(:runner) { double('Runner', call: true) }

  after do
    FileUtils.remove_entry(workspace)
  end

  describe '#clone' do
    context 'with no existing clones' do
      execute(:results) do
        cloner.clone
      end

      it 'clones derisk_common' do
        expect(runner).to have_received(:call).with(
          'git', 'clone', 'https://github.com/DeriskLabs/AI-derisk_common.git',
          File.join(target_dir, 'derisk_common')
        )
      end

      it 'clones derisk_ruby' do
        expect(runner).to have_received(:call).with(
          'git', 'clone', 'https://github.com/DeriskLabs/AI-derisk_ruby.git',
          File.join(target_dir, 'derisk_ruby')
        )
      end

      it 'clones derisk_rails' do
        expect(runner).to have_received(:call).with(
          'git', 'clone', 'https://github.com/DeriskLabs/AI-derisk_rails.git',
          File.join(target_dir, 'derisk_rails')
        )
      end

      it 'clones derisk_layers' do
        expect(runner).to have_received(:call).with(
          'git', 'clone', 'https://github.com/DeriskLabs/AI-derisk_layers.git',
          File.join(target_dir, 'derisk_layers')
        )
      end

      it 'reports every collection cloned' do
        expect(results).to eq(
          'derisk_common' => :cloned, 'derisk_ruby' => :cloned,
          'derisk_rails' => :cloned, 'derisk_layers' => :cloned
        )
      end
    end

    context 'with a collection already cloned' do
      before do
        FileUtils.mkdir_p(File.join(target_dir, 'derisk_common', '.git'))
      end

      execute(:results) do
        cloner.clone
      end

      it 'pulls the existing clone' do
        expect(runner).to have_received(:call).with(
          'git', '-C', File.join(target_dir, 'derisk_common'), 'pull', '--ff-only'
        )
      end

      it 'reports the collection pulled' do
        expect(results.fetch('derisk_common')).to be(:pulled)
      end

      it 'still clones the collections without clones' do
        expect(results.fetch('derisk_layers')).to be(:cloned)
      end
    end

    context 'with a custom base url' do
      let(:base_url) { 'git@github.com:Acme' }

      execute do
        cloner.clone
      end

      it 'clones from the custom url' do
        expect(runner).to have_received(:call).with(
          'git', 'clone', 'git@github.com:Acme/AI-derisk_common.git',
          File.join(target_dir, 'derisk_common')
        )
      end
    end

    context 'when a git command fails' do
      let(:runner) { double('Runner', call: false) }

      it 'raises GitCommandFailed naming the collection' do
        expect do
          cloner.clone
        end.to raise_error(described_class::GitCommandFailed, /derisk_common/)
      end
    end
  end
end
