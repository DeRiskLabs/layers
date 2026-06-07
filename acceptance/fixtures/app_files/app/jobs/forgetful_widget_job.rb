# frozen_string_literal: true

class ForgetfulWidgetJob < ApplicationJob
  include Layers::BaseJob
  use_case 'use_cases/widgets/create'
  fire_and_forget
end
