conn = ActiveRecord::Base.connection

RSpec.shared_examples 'Foreign Keys' do
  describe 'DB Supports Foreign Keys', if: conn.supports_foreign_keys? do
    context 'Permissions Foreign Keys' do
      it 'should have a foreign key' do
        expect(table_has_fk('permissions', 'role_id')).to be true
      end
    end

    context 'Api Subject Roles Foreign Keys' do
      it 'should have a subject_id foreign key' do
        expect(table_has_fk('api_subject_roles', 'api_subject_id')).to be true
      end
      it 'should have a role_id foreign key' do
        expect(table_has_fk('api_subject_roles', 'role_id')).to be true
      end
    end

    context 'Subject Roles Foreign Keys' do
      it 'should have a subject_id foreign key' do
        expect(table_has_fk('subject_roles', 'subject_id')).to be true
      end
      it 'should have a role_id foreign key' do
        expect(table_has_fk('subject_roles', 'role_id')).to be true
      end
    end

    def table_has_fk(table, foreign_key)
      if ActiveRecord::Base.connection.foreign_keys(table).find do |fk|
        fk.options[:column] == foreign_key
      end.nil?
        return false
      else
        return true
      end
    end
  end
end
