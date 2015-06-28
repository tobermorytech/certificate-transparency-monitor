Sequel.migration do
	change do
		alter_table :tree_heads do
			add_column :retrieved_at, Time
		end
	end
end
