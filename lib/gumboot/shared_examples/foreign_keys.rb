RSpec.shared_examples 'Gumboot Foreign Keys' do
  RSpec.shared_examples 'gumboot fk' do
    let(:conn) do
      ActiveRecord::Base.connection
    end

    let(:foreign_key) do
      conn.foreign_keys(from_table).find do |key|
        key.options[:column] == column
      end
    end

    it 'has valid foreign key' do
      if conn.supports_foreign_keys?
        expect(foreign_key).to(be_truthy)
        expect(foreign_key.to_table).to eql to_table
      end
    end
  end

  context 'Permission' do
    include_examples 'gumboot fk' do
      let(:from_table) { 'permissions' }
      let(:to_table) { 'roles' }
      let(:column) { 'role_id' }
    end
  end

  context 'API Subject' do
    context 'Roles' do
      include_examples 'gumboot fk' do
        let(:from_table) { 'api_subject_roles' }
        let(:to_table) { 'api_subjects' }
        let(:column) { 'api_subject_id' }
      end
    end
  end

  context 'Subject' do
    context 'Roles' do
      include_examples 'gumboot fk' do
        let(:from_table) { 'subject_roles' }
        let(:to_table) { 'subjects' }
        let(:column) { 'subject_id' }
      end
    end
  end

  context 'Role' do
    context 'Subjects' do
      include_examples 'gumboot fk' do
        let(:from_table) { 'subject_roles' }
        let(:to_table) { 'roles' }
        let(:column) { 'role_id' }
      end
    end
    context 'API Subject' do
      include_examples 'gumboot fk' do
        let(:from_table) { 'api_subject_roles' }
        let(:to_table) { 'roles' }
        let(:column) { 'role_id' }
      end
    end
  end
end
