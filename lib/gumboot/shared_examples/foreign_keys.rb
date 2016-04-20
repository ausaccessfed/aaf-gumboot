RSpec.shared_examples 'Foreign Keys' do
  conn = ActiveRecord::Base.connection
  context 'Permissions Foreign Keys', if: conn.supports_foreign_keys? do
    let(:permission_fk) do
      conn.foreign_keys(:permissions).find do |fk|
        fk.options[:column] == 'role_id'
      end
    end
    it 'should have a foreign key' do
      expect(permission_fk).to_not be_nil
    end
  end

  context 'Api Subject Roles Foreign Keys', if: conn.supports_foreign_keys? do
    let(:subject_id) do
      conn.foreign_keys(:api_subject_roles).find do |fk|
        fk.options[:column] == 'api_subject_id'
      end
    end
    let(:role_id) do
      conn.foreign_keys(:api_subject_roles).find do |fk|
        fk.options[:column] == 'role_id'
      end
    end
    it 'should have a subject_id foreign key' do
      expect(subject_id).to_not be_nil
    end
    it 'should have a role_id foreign key' do
      expect(role_id).to_not be_nil
    end
  end

  context 'Subject Roles Foreign Keys', if: conn.supports_foreign_keys? do
    let(:subject_id) do
      conn.foreign_keys(:subject_roles).find do |fk|
        fk.options[:column] == 'subject_id'
      end
    end
    let(:role_id) do
      conn.foreign_keys(:subject_roles).find do |fk|
        fk.options[:column] == 'role_id'
      end
    end
    it 'should have a subject_id foreign key' do
      expect(subject_id).to_not be_nil
    end
    it 'should have a role_id foreign key' do
      expect(role_id).to_not be_nil
    end
  end
end
