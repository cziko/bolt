require 'yaml'
# Why Bolt? Cause it's a cool name, that's why :)
module Bolt
  
  # static location for settings
  @@config = {}
  
  # set a config setting
  def self.set(key, value)
    @@config[key] = value
  end
  
  # retrieve a value for a config setting
  def self.get(key)
    @@config[key]
  end
  
  # convienience accessor
  def self.[](key)
    @@config[key]
  end
  
  # read the .bolt file for configuration
  def self.read_dotfile
    if File.exists?('.bolt')
      $stdout.puts "** Found .bolt file"
      read = YAML.load_file('.bolt')
      @@config.merge!(read) if read
    end
  end
  
  def self.start
    $stdout.puts "** Starting Bolt..."
    
    # read the dotfile
    Bolt.read_dotfile
    
    Bolt::Listener.new
  end
  
  autoload :Mapper, 'bolt/mapper'
  autoload :Runner, 'bolt/runner'
  autoload :Notifier, 'bolt/notifier'
  autoload :Listener, 'bolt/listener'
  
  #
  # Bolt::Listeners
  #
  # Wrapper for specific listeners
  #
  module Listeners
    autoload :Generic, 'bolt/listeners/generic'
    autoload :Kqueue, 'bolt/listeners/kqueue'
    autoload :Osx, 'bolt/listeners/osx'
  end
  
  #
  # Bolt::Runners
  #
  # Wrapper for specific runners
  #
  module Runners
    @@noticed_files = []
    
    def self.files=(arr)
      @@noticed_files = arr
    end
    
    def self.files
      @@noticed_files
    end
    
    autoload :Cucumber, 'bolt/runners/cucumber'
    autoload :TestUnit, 'bolt/runners/test_unit'
    autoload :RSpec, 'bolt/runners/rspec'
  end
    
  #
  # Bolt::Notifiers
  #
  # Wrapper for specific notifier
  #
  module Notifiers
    autoload :Generic, 'bolt/notifiers/generic'
    autoload :Growl, 'bolt/notifiers/growl'
    autoload :NotifyOsd, 'bolt/notifiers/notify_osd'
  end
end
