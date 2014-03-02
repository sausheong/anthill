require 'sequel'

Sequel.migration do
  change do
    create_table :program do
      primary_key :id
      DateTime :created_at
      Text :code
      String :name, size: 255        
    end
  end  
end