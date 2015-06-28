Sequel.migration do
	change do
		alter_table :log_entries do
			add_index :certificate_id
		end
	end
end
