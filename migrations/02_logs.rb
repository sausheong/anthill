Sequel.migration do
  change do
    create_table :log do
      primary_key :id
      DateTime :created_at
      Text :content
      Integer :level, default: 2
    end
  end  
end