# frozen_string_literal: true

Rails.application.routes.draw do
  resources :widgets, only: [:index, :create]
end
