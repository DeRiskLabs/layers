# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/component/component_templates'

module Layers
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      include ComponentTemplates

      AUTOLOAD_LIB = /config\.autoload_lib\(ignore: %w\[[^\]]*\]\)/

      def create_gemspec
        create_file component_path("#{file_name}.gemspec"), gemspec
      end

      def create_gemfile
        create_file component_path('Gemfile'), gemfile
      end

      def create_root_constant
        create_file component_path('lib', "#{file_name}.rb"), root_constant
      end

      def create_version
        create_file component_path('lib', file_name, 'version.rb'), version
      end

      def create_spec_helper
        create_file component_path('spec', 'spec_helper.rb'), spec_helper
      end

      def create_component_spec
        create_file component_path('spec', "#{file_name}_spec.rb"), component_spec
      end

      def create_rubocop_config
        create_file component_path('.rubocop.yml'), rubocop_config
      end

      def create_readme
        create_file component_path('README.md'), readme
      end

      def create_isolation_runner
        create_file 'bin/test_components', isolation_runner
        chmod 'bin/test_components', 0o755
      end

      def ignore_component_in_autoloader
        gsub_file 'config/application.rb', AUTOLOAD_LIB do |match|
          match.include?(file_name) ? match : match.sub(']', " #{file_name}]")
        end
      end


      private

      def component_path(*segments)
        File.join('lib', file_name, *segments)
      end

      def module_name
        file_name.camelize
      end
    end
  end
end
