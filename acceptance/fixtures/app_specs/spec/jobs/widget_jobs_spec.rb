# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'jobs as thin boundaries' do
  it 'performs the use case to success' do
    CreateWidgetJob.perform_now(name: 'job-widget')
    expect(Widget.exists?(name: 'job-widget')).to be(true)
  end

  it 'raises JobFailed carrying the failure messages' do
    expect { CreateWidgetJob.perform_now(name: '') }
      .to raise_error(Layers::BaseJob::JobFailed, /Name can't be blank/)
  end

  it 'swallows failures under fire_and_forget' do
    expect { ForgetfulWidgetJob.perform_now(name: '') }.not_to raise_error
  end
end
