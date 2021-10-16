Hanami::Model.migration do
  change do
    alter_table :covid_stats do
      add_column :tests_to_date, Integer, null: false, default: -1
    end
  end
end
