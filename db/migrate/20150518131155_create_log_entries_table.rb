Sequel.migration do
	change do
		create_table :log_entries do
			primary_key :id, :type => :uuid, :default => Sequel.function(:uuid_generate_v4)

			uuid   :log_id
			Bignum :ordinal, :null => false

			bytea  :leaf_input
			bytea  :extra_data

			index [:log_id, :ordinal], :unique => true
		end
	end
end
