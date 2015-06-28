Sequel.migration do
	change do
		create_table :certificates do
			primary_key :id, :type => :bytea

			bytea :der, :null => false
			Time  :indexed_at

			foreign_key :issuer_id, :certificates, :type => :bytea
		end
	end
end
