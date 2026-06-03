# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL do
  it { expect(Layers::DSL::MissingRequiredInputs.ancestors).to include(ArgumentError) }
  it { expect(Layers::DSL::UnexpectedInputs.ancestors).to include(ArgumentError) }
  it { expect(Layers::DSL::NotImplementedError.ancestors).to include(::NotImplementedError) }
end
