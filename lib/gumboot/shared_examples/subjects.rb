# frozen_string_literal: true
RSpec.shared_examples 'Subjects' do
  context 'AAF shared implementation' do
    subject { build :subject }

    it { is_expected.to be_valid }
    it { is_expected.to be_an(Accession::Principal) }
    it { is_expected.to respond_to(:roles) }
    it { is_expected.to respond_to(:permissions) }
    it { is_expected.to respond_to(:permits?) }
    it { is_expected.to respond_to(:functioning?) }

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without mail' do
      subject.mail = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without an enabled state' do
      subject.enabled = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without a complete state' do
      subject.complete = nil
      expect(subject).not_to be_valid
    end
  end
end
