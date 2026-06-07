# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'widgets endpoints', type: :request do
  describe 'POST /widgets' do
    context 'with a valid name' do
      before { post '/widgets', params: { name: 'http-widget' }, as: :json }

      it 'is created' do
        expect(response).to have_http_status(201)
      end

      it 'renders the widget' do
        expect(JSON.parse(response.body)['name']).to eq('http-widget')
      end
    end

    context 'with invalid input' do
      before { post '/widgets', params: { name: '' }, as: :json }

      it 'is unprocessable' do
        expect(response).to have_http_status(422)
      end

      it 'carries errors' do
        expect(JSON.parse(response.body)['errors']).to be_any
      end
    end
  end

  describe 'GET /widgets' do
    before do
      ['beta', 'alpha', 'gamma'].each { |name| Widget.create!(name: name) }
      get '/widgets', params: { page: 1, per: 2 }
    end

    it 'is ok' do
      expect(response).to have_http_status(200)
    end

    it 'returns the ordered, paginated collection' do
      expect(JSON.parse(response.body).map { |w| w['name'] }).to eq(['alpha', 'beta'])
    end
  end
end
