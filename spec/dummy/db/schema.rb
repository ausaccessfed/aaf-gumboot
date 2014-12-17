ActiveRecord::Schema.define(version: 0) do
  create_table :roles do |t|
    t.string :name
    t.timestamps
  end

  create_table :permissions do |t|
    t.string :value
    t.belongs_to :role
    t.timestamps
  end

  create_table :api_subjects do |t|
    t.string :x509_dn
    t.timestamps
  end

  create_table :api_subject_roles do |t|
    t.belongs_to :api_subject
    t.belongs_to :role
    t.timestamps
  end
end
