# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::BaseForm do
  subject(:form) { form_class.new(**form_attributes) }

  let(:form_class) { described_class }
  let(:form_attributes) { {} }

  describe 'composition' do
    it 'includes ActiveModel::Model' do
      expect(described_class.include?(ActiveModel::Model)).to be(true)
    end
  end

  describe 'model duck typing' do
    it { is_expected.to respond_to(:valid?) }
    it { is_expected.to respond_to(:errors) }
    it { is_expected.to respond_to(:new_record?) }
    it { is_expected.to respond_to(:persisted?) }
  end

  describe '#persisted?' do
    it 'defaults to false' do
      expect(form.persisted?).to be(false)
    end

    context 'when persisted is written' do
      subject(:form) { form_class.new(**form_attributes).tap { |f| f.persisted = true } }

      it 'returns true' do
        expect(form.persisted?).to be(true)
      end
    end
  end

  describe '#new_record?' do
    it 'mirrors persisted?' do
      expect(form.new_record?).to be(true)
    end

    context 'when persisted is written' do
      subject(:form) { form_class.new(**form_attributes).tap { |f| f.persisted = true } }

      it 'returns false' do
        expect(form.new_record?).to be(false)
      end
    end
  end

  describe '#form_error_messages' do
    let(:form_class) do
      Class.new(described_class) do
        attr_accessor :name,
                      :internal_token

        validates :name, presence: true
        validates :internal_token, presence: true

        def self.name
          'RegistrationForm'
        end


        private

        def report_full_errors_for
          [:name]
        end
      end
    end

    execute do
      form.valid?
    end

    it 'surfaces full messages for whitelisted attributes' do
      expect(form.form_error_messages).to contain_exactly("Name can't be blank")
    end

    it 'collects errors for every attribute regardless of the whitelist' do
      expect(form.errors.attribute_names).to contain_exactly(:name, :internal_token)
    end

    context 'when the whitelisted attribute is valid' do
      let(:form_attributes) { { name: 'Ada' } }

      it 'returns an empty collection' do
        expect(form.form_error_messages).to be_empty
      end
    end

    context 'with the default whitelist' do
      let(:form_class) do
        Class.new(described_class) do
          attr_accessor :name

          validates :name, presence: true

          def self.name
            'BareForm'
          end
        end
      end

      it 'surfaces nothing' do
        expect(form.form_error_messages).to be_empty
      end
    end
  end
end
