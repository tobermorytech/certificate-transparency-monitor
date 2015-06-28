Sequel.migration do
	change do
		alter_table :logs do
			add_column :base_url,   String, :null => false
			add_column :public_key, :bytea, :null => false
		end
	end
end
