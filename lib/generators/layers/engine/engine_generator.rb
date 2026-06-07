# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/engine/engine_templates'

module Layers
  module Generators
    class EngineGenerator < Rails::Generators::NamedBase
      include EngineTemplates

      class_option :family, type: :string, default: 'feature',
                            desc: "Engine family: 'feature' (engines/) or 'api' (apis/)"

      def validate_family!
        return if ['feature', 'api'].include?(options[:family])

        fail Thor::Error, "Unknown engine family '#{options[:family]}' (use feature or api)"
      end

      def create_gem_shell
        create_file engine_path("#{file_name}.gemspec"), gemspec_content
        create_file engine_path('Gemfile'), gemfile_content
        create_file engine_path('Rakefile'), rakefile_content
        create_file engine_path('README.md'), readme_content
      end

      def create_lib
        create_file engine_path("lib/#{file_name}.rb"), root_file_content
        create_file engine_path("lib/#{file_name}/version.rb"), version_content
        create_file engine_path("lib/#{file_name}/engine.rb"), engine_content
      end

      def create_routes
        create_file engine_path('config/routes.rb'), routes_content
      end

      def create_application_controller
        create_file engine_path("app/controllers/#{file_name}/application_controller.rb"),
                    application_controller_content
      end

      def create_layer_bases
        create_file engine_path("app/lib/use_cases/#{file_name}/base_use_case.rb"),
                    use_case_base_content
        create_file engine_path("app/lib/user_stories/#{file_name}/base_user_story.rb"),
                    user_story_base_content
      end

      def create_spec_home
        create_file engine_path('spec/.keep'), ''
      end

      def register_in_gemfile
        unless File.exist?(File.join(destination_root, 'Gemfile'))
          return say("add to your Gemfile: path '#{family_dir}' do gem '#{file_name}' end")
        end

        if app_gemfile.include?("path '#{family_dir}' do")
          inject_into_file 'Gemfile', "  gem '#{file_name}'\n", after: "path '#{family_dir}' do\n"
        else
          append_to_file 'Gemfile', "\npath '#{family_dir}' do\n  gem '#{file_name}'\nend\n"
        end
      end

      def mount_engine
        unless File.exist?(File.join(destination_root, 'config/routes.rb'))
          return say("add to your routes: #{mount_line}")
        end

        inject_into_file 'config/routes.rb', "  #{mount_line}\n",
                         after: /Rails\.application\.routes\.draw do[^\n]*\n/
      end


      private

      def api?
        options[:family] == 'api'
      end

      def family_dir
        api? ? 'apis' : 'engines'
      end

      def engine_path(relative)
        File.join(family_dir, file_name, relative)
      end

      def app_gemfile
        File.read(File.join(destination_root, 'Gemfile'))
      end

      def mount_line
        "mount #{class_name}::Engine, at: '#{mount_path}'"
      end

      def mount_path
        api? ? "/#{file_name}" : '/'
      end
    end
  end
end
