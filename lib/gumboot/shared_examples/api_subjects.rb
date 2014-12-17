RSpec.shared_examples 'API Subjects' do
  subject { create :api_subject }
  it 'has a valid factory' do
    expect(subject).to be_valid
  end
  it 'is invalid without an x509_dn' do
    subject.x509_dn = nil
    expect(subject).not_to be_valid
  end
  it 'has a relationship to roles' do
    expect(subject).to respond_to(:roles)
  end
end
