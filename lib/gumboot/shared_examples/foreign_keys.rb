def conn
  return ActiveRecord::Base.connection
end

RSpec.shared_examples 'Foreign Keys' do
  describe 'DB Supports Foreign Keys', if: conn.supports_foreign_keys? do
    context 'Permissions Foreign Keys' do
      it 'should have a foreign key' do
        expect(table_has_fk('permissions', 'role_id')).to be true
      end
      it 'should have a foreign key that points to the correct table' do
        expect(fk_exists_between('permissions', 'roles')).to be true
      end
    end

    context 'Api Subject Roles Foreign Keys' do
      context 'api_subject_id foreign key' do
        it 'should have a subject_id foreign key' do
          expect(table_has_fk('api_subject_roles', 'api_subject_id')).to be true
        end
        it 'should have a foreign key that points to the correct table' do
          expect(
            fk_exists_between('api_subject_roles', 'api_subjects')
          ).to be true
        end
      end

      context 'api_subject_id foreign key' do
        it 'should have a role_id foreign key' do
          expect(table_has_fk('api_subject_roles', 'role_id')).to be true
        end
        it 'should have a foreign key that points to the correct table' do
          expect(fk_exists_between('api_subject_roles', 'roles')).to be true
        end
      end
    end

    context 'Subject Roles Foreign Keys' do
      context 'subject_id foreign key' do
        it 'should have a subject_id foreign key' do
          expect(table_has_fk('subject_roles', 'subject_id')).to be true
        end
        it 'should have a foreign key that points to the correct table' do
          expect(fk_exists_between('subject_roles', 'subjects')).to be true
        end
      end
      context 'role_id foreign key' do
        it 'should have a role_id foreign key' do
          expect(table_has_fk('subject_roles', 'role_id')).to be true
        end
        it 'should have a foreign key that points to the correct table' do
          expect(fk_exists_between('subject_roles', 'roles')).to be true
        end
      end
    end

    def table_has_fk(table, foreign_key)
      f = conn.foreign_keys(table).find do |fk|
        fk.options[:column] == foreign_key
      end
      return false if f.nil?
      true
    end

    def fk_exists_between(from_table, to_table)
      f = conn.foreign_keys(from_table).find do |fk|
        fk[:to_table] == to_table
      end
      return false if f.nil?
      true
    end
  end
end
