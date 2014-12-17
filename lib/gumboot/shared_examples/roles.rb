RSpec.shared_examples 'Roles' do
  subject { create :role }
  it 'has a valid factory' do
    expect(subject).to be_valid
  end
  it 'is invalid without a name' do
    subject.name = nil
    expect(subject).not_to be_valid
  end
  it 'has a relationship to api_subjects' do
    expect(subject).to respond_to(:api_subjects)
  end
end
