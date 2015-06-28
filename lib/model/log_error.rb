class LogError < Sequel::Model
	many_to_one :log
	many_to_one :tree_head
end
