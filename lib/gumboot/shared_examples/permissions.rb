# frozen_string_literal: true
RSpec.shared_examples 'Permissions' do
  context 'AAF shared implementation' do
    subject { build :permission }

    it { is_expected.to be_valid }

    it 'is invalid without a role' do
      subject.role = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without a value' do
      subject.value = nil
      expect(subject).not_to be_valid
    end

    it 'allows wildcard values' do
      subject.value = '*'
      expect(subject).to be_valid
    end

    it 'allows permission string values' do
      subject.value = 'a:b:c:d'
      expect(subject).to be_valid
    end

    it 'disallows invalid characters' do
      subject.value = 'a:b:%'
      expect(subject).not_to be_valid
    end

    it 'must have a unique value per role' do
      other = create(:permission, role: subject.role, value: 'other')

      expect { subject.value = other.value }
        .to change { subject.valid? }.to(be_falsey)
    end

    it 'can have a value used in a different role' do
      other = create(:permission, value: 'other')
      subject.value = other.value
      expect(subject).to be_valid
    end
  end
end
