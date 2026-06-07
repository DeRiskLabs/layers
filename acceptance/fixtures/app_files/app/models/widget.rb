# frozen_string_literal: true

class Widget < ApplicationRecord
  validates :name, presence: true
end
