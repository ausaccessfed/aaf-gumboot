# frozen_string_literal: true

RSpec.shared_examples 'API constraints' do
  context 'AAF shared implementation' do
    context '#matches?' do
      context 'with default: false' do
        subject { described_class.new(version: '1', default: false) }

        it 'is true for a valid request' do
          expect(subject.matches?(matching_request)).to be_truthy
        end

        it 'is false for a non-matching request' do
          expect(subject.matches?(non_matching_request)).to be_falsey
        end
      end

      context 'with default: true' do
        subject { described_class.new(version: '1', default: true) }

        it 'is true for a valid request' do
          expect(subject.matches?(matching_request)).to be_truthy
        end

        it 'is true for a non-matching request' do
          expect(subject.matches?(non_matching_request)).to be_truthy
        end
      end
    end
  end
end
