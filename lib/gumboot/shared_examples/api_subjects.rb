RSpec.shared_examples 'API Subjects' do
  context 'AAF shared implementation' do
    subject { build :api_subject }

    it { is_expected.to be_valid }
    it { is_expected.to be_an(Accession::Principal) }
    it { is_expected.to respond_to(:roles) }
    it { is_expected.to respond_to(:permissions) }
    it { is_expected.to respond_to(:permits?) }
    it { is_expected.to respond_to(:functioning?) }

    it 'is invalid without an x509_cn' do
      subject.x509_cn = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid if an x509 value is not unique' do
      create(:api_subject, x509_cn: subject.x509_cn)
      expect(subject).not_to be_valid
    end
    it 'is invalid without a description' do
      subject.description = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without a contact name' do
      subject.contact_name = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without a contact mail address' do
      subject.contact_mail = nil
      expect(subject).not_to be_valid
    end
    it 'is invalid without an enabled state' do
      subject.enabled = nil
      expect(subject).not_to be_valid
    end
  end
end
