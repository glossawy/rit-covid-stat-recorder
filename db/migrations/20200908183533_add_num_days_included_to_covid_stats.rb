Hanami::Model.migration do
  change do
    alter_table :covid_stats do
      add_column :num_days_included, Integer, null: false, default: -1
    end
  end
end
