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
  end
end
