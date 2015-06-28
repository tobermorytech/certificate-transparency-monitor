Sequel.migration do
	change do
		execute "UPDATE tree_heads SET retrieved_at=timestamp WHERE retrieved_at IS NULL"

		alter_table :tree_heads do
			set_column_not_null :retrieved_at
		end
	end
end
