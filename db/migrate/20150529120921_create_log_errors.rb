Sequel.migration do
	change do
		create_table :log_errors do
			uuid :id, :primary_key => true, :default => Sequel.function(:uuid_generate_v4)

			Time :when, :null => false

			foreign_key :log_id, :logs, :type => :uuid, :null => false
			foreign_key :tree_head_id, :tree_heads, :type => :uuid

			String :details, :null => false
		end
	end
end
