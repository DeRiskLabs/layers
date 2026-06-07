# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/skills/installer'
require 'layers/skills/cloner'
require 'tmpdir'

RSpec.describe Layers::Skills::Installer do
  subject(:installer) { described_class.new(target_dir: target_dir, specs: specs) }

  let(:workspace) { Dir.mktmpdir }
  let(:target_dir) { File.join(workspace, 'skills') }
  let(:specs) { [layers_collection_spec] }
  let(:layers_collection_spec) do
    instance_double(Gem::Specification, name: 'ai-derisk_layers', full_gem_path: layers_gem_root)
  end
  let(:layers_gem_root) { File.join(workspace, 'gems', 'ai-derisk_layers-0.1.0') }

  before do
    FileUtils.mkdir_p(File.join(layers_gem_root, 'authoring-use-cases', 'references'))
    File.write(File.join(layers_gem_root, 'INDEX.md'), '# derisk_layers')
    File.write(File.join(layers_gem_root, 'authoring-use-cases', 'SKILL.md'), '# Authoring')
    File.write(File.join(layers_gem_root, 'authoring-use-cases', 'references', 'checklist.md'), '#')
    File.write(File.join(layers_gem_root, '.gitignore'), '*.gem')
    File.write(File.join(layers_gem_root, 'ai-derisk_layers.gemspec'), 'Gem::Specification.new')
  end

  after do
    FileUtils.remove_entry(workspace)
  end

  describe '#install' do
    context 'with one installed collection' do
      execute(:installed) do
        installer.install
      end

      it 'returns the installed collection names' do
        expect(installed).to eq(['derisk_layers'])
      end

      it 'copies the collection index' do
        expect(File.read(File.join(target_dir, 'derisk_layers',
                                   'INDEX.md'))).to eq('# derisk_layers')
      end

      it 'copies skill documents' do
        expect(File).to exist(File.join(target_dir, 'derisk_layers', 'authoring-use-cases',
                                        'SKILL.md'))
      end

      it 'copies reference documents' do
        expect(File)
          .to exist(File.join(target_dir, 'derisk_layers', 'authoring-use-cases', 'references',
                              'checklist.md'))
      end

      it 'does not copy hidden files' do
        expect(File).not_to exist(File.join(target_dir, 'derisk_layers', '.gitignore'))
      end

      it 'does not copy the gemspec' do
        expect(File).not_to exist(File.join(target_dir, 'derisk_layers',
                                            'ai-derisk_layers.gemspec'))
      end
    end

    context 'with a stale skill already in the target' do
      before do
        FileUtils.mkdir_p(File.join(target_dir, 'derisk_layers', 'renamed-away-skill'))
      end

      execute do
        installer.install
      end

      it 'removes skills no longer in the collection' do
        expect(File).not_to exist(File.join(target_dir, 'derisk_layers', 'renamed-away-skill'))
      end
    end

    context 'with multiple installed collections' do
      let(:specs) { [layers_collection_spec, ruby_collection_spec] }
      let(:ruby_collection_spec) do
        instance_double(Gem::Specification, name: 'ai-derisk_ruby', full_gem_path: ruby_gem_root)
      end
      let(:ruby_gem_root) { File.join(workspace, 'gems', 'ai-derisk_ruby-0.1.0') }

      before do
        FileUtils.mkdir_p(File.join(ruby_gem_root, 'ruby-testing'))
        File.write(File.join(ruby_gem_root, 'ruby-testing', 'SKILL.md'), '# Ruby Testing')
      end

      execute(:installed) do
        installer.install
      end

      it 'returns the collection names sorted' do
        expect(installed).to eq(['derisk_layers', 'derisk_ruby'])
      end

      it 'installs each collection into its own directory' do
        expect(File).to exist(File.join(target_dir, 'derisk_ruby', 'ruby-testing', 'SKILL.md'))
      end
    end

    context 'with no skill collections installed' do
      let(:specs) { [] }

      it 'raises NoSkillCollections' do
        expect do
          installer.install
        end.to raise_error(described_class::NoSkillCollections)
      end
    end
  end

  describe '.installed_specs' do
    let(:loaded_layers_spec) { instance_double(Gem::Specification, name: 'ai-derisk_layers') }
    let(:unrelated_spec) { instance_double(Gem::Specification, name: 'rake') }
    let(:installed_ruby_spec) { instance_double(Gem::Specification, name: 'ai-derisk_ruby') }
    let(:installed_layers_duplicate) { instance_double(Gem::Specification, name: 'ai-derisk_layers') }

    before do
      allow(Gem).to receive(:loaded_specs)
        .and_return('ai-derisk_layers' => loaded_layers_spec, 'rake' => unrelated_spec)
      allow(Gem::Specification).to receive(:latest_specs).with(true)
                                                         .and_return([installed_ruby_spec,
                                                                      installed_layers_duplicate])
    end

    execute(:installed_specs) do
      described_class.installed_specs
    end

    it 'selects skill collection gems, preferring loaded specs over installed duplicates' do
      expect(installed_specs).to contain_exactly(loaded_layers_spec, installed_ruby_spec)
    end
  end
end
