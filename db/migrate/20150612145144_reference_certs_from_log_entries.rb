Sequel.migration do
	change do
		alter_table :log_entries do
			add_foreign_key :certificate_id, :certificates, :type => :bytea
		end
	end
end
