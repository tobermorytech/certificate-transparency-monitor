Sequel.migration do
	change do
		create_table :roots do
			uuid :log_id,          :null => false
			bytea :certificate_id, :null => false
		end
	end
end
