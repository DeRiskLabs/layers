# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Error do
  it { expect(described_class.ancestors).to include(StandardError) }
end
