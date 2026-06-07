# frozen_string_literal: true

class CreateWidgetJob < ApplicationJob
  include Layers::BaseJob
  use_case 'use_cases/widgets/create'
end
