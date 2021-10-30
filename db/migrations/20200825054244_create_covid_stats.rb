Hanami::Model.migration do
  change do
    create_table :covid_stats do
      primary_key :id

      column :campus_status, String, null: false
      column :new_cases_students, Integer, null: false
      column :new_cases_employees, Integer, null: false
      column :quarantined_on_campus, Integer, null: false
      column :quarantined_off_campus, Integer, null: false
      column :isolated_on_campus, Integer, null: false
      column :isolated_off_campus, Integer, null: false
      column :isolation_bed_availability, Integer, null: false
      column :surveillance_positive_ratio, Integer, null: false

      column :last_updated_at, DateTime, null: false
      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
