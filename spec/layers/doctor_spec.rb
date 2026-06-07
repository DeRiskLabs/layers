# frozen_string_literal: true

require 'layers_spec_helper'
require 'layers/doctor'
require 'tmpdir'
require 'fileutils'

RSpec.describe Layers::Doctor do
  subject(:doctor) { described_class.new(root: root) }

  let(:root) { Dir.mktmpdir('doctor') }

  after { FileUtils.remove_entry(root) }

  def write(relative, contents = '')
    path = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def mkslice(slice)
    FileUtils.mkdir_p(File.join(root, slice))
  end

  context 'with no slices' do
    it 'is ok' do
      expect(doctor).to be_ok
    end
  end

  context 'with a well-formed engine' do
    before do
      write('Gemfile', "path 'engines' do\n  gem 'billing'\nend\n")
      write('bin/test_suite', "#!/usr/bin/env bash\n")
      write('engines/billing/Gemfile', "source 'https://rubygems.org'\n")
      mkslice('engines/billing/spec')
    end

    it 'is ok' do
      expect(doctor).to be_ok
    end
  end

  context 'with an engine missing its Gemfile' do
    before do
      write('Gemfile', "path 'engines' do\n  gem 'billing'\nend\n")
      write('bin/test_suite', '')
      mkslice('engines/billing/spec')
    end

    it 'reports the missing Gemfile' do
      expect(doctor.problems.map(&:message).join).to include('no Gemfile')
    end
  end

  context 'with an engine not consumed via a path block' do
    before do
      write('Gemfile', "source 'https://rubygems.org'\n")
      write('bin/test_suite', '')
      write('engines/billing/Gemfile', '')
      mkslice('engines/billing/spec')
    end

    it 'reports the missing path block' do
      expect(doctor.problems.map(&:message).join).to include('not consumed via')
    end
  end

  context 'with a slice missing its spec directory' do
    before do
      write('Gemfile', "path 'components' do\n  gem 'billing'\nend\n")
      write('bin/test_suite', '')
      write('components/billing/Gemfile', '')
    end

    it 'reports the missing spec directory' do
      expect(doctor.problems.map(&:message).join).to include('no spec/ directory')
    end
  end

  context 'with slices but no suite runner' do
    before do
      write('Gemfile', "path 'engines' do\n  gem 'billing'\nend\n")
      write('engines/billing/Gemfile', '')
      mkslice('engines/billing/spec')
    end

    it 'reports the missing bin/test_suite' do
      expect(doctor.problems.map(&:message).join).to include('no bin/test_suite')
    end
  end
end
