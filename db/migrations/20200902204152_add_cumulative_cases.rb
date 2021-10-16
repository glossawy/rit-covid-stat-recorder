Hanami::Model.migration do
  change do
    alter_table :covid_stats do 
      add_column :total_cases_students, Integer, null: false, default: -1
      add_column :total_cases_employees, Integer, null: false, default: -1
    end
  end
end
