RSpec.shared_examples 'Permissions' do
  subject { create :permission }
  it 'has a valid factory' do
    expect(subject).to be_valid
  end
  it 'is invalid without a role' do
    subject.role = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without a value' do
    subject.value = nil
    expect(subject).not_to be_valid
  end
end
