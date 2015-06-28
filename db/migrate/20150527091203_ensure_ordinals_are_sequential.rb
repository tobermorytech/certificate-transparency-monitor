Sequel.migration do
	up do
		execute %{
		  CREATE FUNCTION ordinal_is_contiguous(_log_id uuid, _ordinal bigint)
		    RETURNS bool AS $$
		      BEGIN
		        RETURN _ordinal=0 OR
		               EXISTS (SELECT * FROM log_entries
		                               WHERE log_entries.log_id=_log_id
		                                 AND log_entries.ordinal=_ordinal-1
		                      );
		      END;
		    $$
		    LANGUAGE plpgsql
		}

		execute "ALTER TABLE log_entries
		            ADD CONSTRAINT ordinal_is_contiguous
		                     CHECK (ordinal_is_contiguous(log_id, ordinal))"
	end

	down do
		execute "DROP FUNCTION ordinal_is_contiguous CASCADE"
	end
end
