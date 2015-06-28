Sequel.migration do
	change do
		alter_table :tree_heads do
			add_column :hash_correct, :boolean
		end
	end
end
