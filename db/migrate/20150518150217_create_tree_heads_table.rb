Sequel.migration do
	change do
		create_table :tree_heads do
			primary_key :id,
			            :type => :uuid,
			            :default => Sequel.function(:uuid_generate_v4)

			bytea  :root_hash, :null => false
			bytea  :signature, :null => false
			Bignum :size,      :null => false
			Time   :timestamp, :null => false

			foreign_key :log_id, :logs, :type => :uuid
		end
	end
end
