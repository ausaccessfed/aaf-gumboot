def conn
  ActiveRecord::Base.connection
end

RSpec.shared_examples 'fk' do |from_table, to_table, fk|
  context "Configured between '#{from_table}' and '#{to_table}' tables", if:
    conn.supports_foreign_keys? do
    it "'#{from_table}' table should have '#{fk}' configured as a foreign
    key'" do
      expect(table_has_fk(from_table, fk)).to be_truthy
    end
    it "the '#{fk}' foreign key in the '#{from_table}' table should point to
      the '#{to_table}' table" do
      expect(fk_exists_between(from_table, to_table, fk)).to be_truthy
    end
  end

  def table_has_fk(table, foreign_key)
    if conn.foreign_keys(table).find do |fk|
      fk.options[:column] == foreign_key
    end.nil?
      return false
    else
      return true
    end
  end

  def fk_exists_between(from_table, to_table, foreign_key)
    if conn.foreign_keys(from_table).find do |fk|
      fk[:to_table] == to_table && fk.options[:column] == foreign_key
    end.nil?
      return false
    else
      return true
    end
  end
end

RSpec.shared_examples 'Foreign Keys' do
  include_examples 'fk', 'permissions', 'roles', 'role_id'
  include_examples(
    'fk',
    'api_subject_roles',
    'api_subjects',
    'api_subject_id'
  )
  include_examples 'fk', 'api_subject_roles', 'roles', 'role_id'
  include_examples 'fk', 'subject_roles', 'subjects', 'subject_id'
  include_examples 'fk', 'subject_roles', 'roles', 'role_id'
end
