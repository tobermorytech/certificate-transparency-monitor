Sequel.migration do
	change do
		alter_table :logs do
			add_column :inactive, :boolean, null: false, default: false
		end
	end
end
