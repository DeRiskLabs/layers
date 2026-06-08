# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'jobs as thin boundaries' do
  describe CreateWidgetJob do
    context 'when the use case succeeds' do
      execute do
        described_class.perform_now(name: 'job-widget')
      end

      it 'performs the use case' do
        expect(Widget.exists?(name: 'job-widget')).to be(true)
      end
    end

    context 'when the use case fails' do
      it 'raises JobFailed carrying the failure messages' do
        expect { described_class.perform_now(name: '') }
          .to raise_error(Layers::BaseJob::JobFailed, /Name can't be blank/)
      end
    end
  end

  describe ForgetfulWidgetJob do
    it 'swallows failures under fire_and_forget' do
      expect { described_class.perform_now(name: '') }.not_to raise_error
    end
  end
end
