require 'sequel'

TIME_FORMAT = 'UTC %l:%M %p'
DATE_FORMAT = '%d-%b-%Y'
DATETIME_FORMAT = 'UTC %k:%M, %d-%b-%y'
DB = Sequel.connect 'postgres://anthill:anthill@localhost:5432/anthill'
DB.extension :pagination

module Loggable
  DEBUG, INFO, WARN, ERROR = 1, 2, 3, 4
  def info(message)
    Log.create(content: message, level: INFO)
  end  
  
  def debug(message)
    Log.create(content: message, level: DEBUG)
  end  
  
  def warn(message)
    Log.create(content: message, level: WARN)
  end  
  
  def error(message)
    Log.create(content: message, level: ERROR)
  end    
end

class Program < Sequel::Model
  include Loggable
  def before_create
    super
    self.created_at = DateTime.now
    info "#{name} has been created."
  end   
  
  def before_destroy
    info "#{name} has been removed."
  end
end

class Log < Sequel::Model
  include Loggable
  def before_create
    super
    self.created_at = DateTime.now
  end   
end

