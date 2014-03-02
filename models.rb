require 'sequel'

DB = Sequel.connect 'postgres://anthill:anthill@localhost:5432/anthill'

class Program < Sequel::Model
  def before_create
    super
    self.created_at = DateTime.now
  end   
end