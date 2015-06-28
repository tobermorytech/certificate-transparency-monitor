Sequel.migration do
	change do
		create_table :logs do
			uuid   :id, :primary_key => true, :default => Sequel.function(:uuid_generate_v4)
			String :name, :null => false
		end
	end
end
