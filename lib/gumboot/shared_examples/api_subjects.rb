RSpec.shared_examples 'API Subjects' do
  subject { build :api_subject }
  it 'has a valid factory' do
    expect(subject).to be_valid
  end
  it 'is invalid without an x509_cn' do
    subject.x509_cn = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without a description' do
    subject.description = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without a contact email' do
    subject.email = nil
    expect(subject).not_to be_valid
  end
  it 'has a relationship to roles' do
    expect(subject).to respond_to(:roles)
  end
  it 'indicates if the Subject is functional' do
    expect(subject).to respond_to(:functioning?)
  end
end
