# frozen_string_literal: true

module Layers
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('tasks/skills.rake', __dir__)
      load File.expand_path('tasks/doctor.rake', __dir__)
    end
  end
end
