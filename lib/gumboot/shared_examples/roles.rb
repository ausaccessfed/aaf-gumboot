RSpec.shared_examples 'Roles' do
  context 'AAF shared implementation' do
    subject { build :role }

    it { is_expected.to be_valid }
    it { is_expected.to respond_to(:api_subjects) }
    it { is_expected.to respond_to(:permissions) }

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end
  end
end
