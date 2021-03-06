#
# Bolt::Runners::Cucumber
#
# The Cucumber Runner maps the filename to the appropriate feature
#
module Bolt
  module Runners
    class Cucumber < Bolt::Runners::Base
      
      # mappings define which folders hold the files that the listener should listen to
      MAPPINGS =  /(\.\/app\/|\.\/lib\/|\.\/features\/)/
      
      # class map specifies the folders holding classes that can be reloaded
      CLASS_MAP = /(app\/controllers\/|app\/models\/|lib\/)/
      
      attr_accessor :notifier, :test_io, :heard, :controllers, :models
      
      # step mother storage
      @@mother = nil
      
      # Save a reference for supplied StepMother 
      def self.mother=(step_mother)
        @@mother = step_mother
      end
      
      # Get the referenced StepMother
      def self.mother
        @@mother
      end
      
      # Create a new Cucumber Runner
      def initialize
        self.controllers = {}
        self.models = {}
        read_map
      end
      
      # Read the feature map located in .bolt file
      def read_map
        if !Bolt['feature_map']
          puts "** ERROR: could not find feature_map in .bolt"
        else
          Bolt['feature_map'].each do |feature, map|
            # controllers
            if map["controllers"].include?(',')
              map["controllers"].split(',').each { |controller| 
                name = controller.strip     
                self.controllers[name] = [] if !self.controllers[name]
                self.controllers[name] << feature
              }
            else
              name = map["controllers"]
              self.controllers[name] = [] if !self.controllers[name]
              self.controllers[name] << feature
            end
            
            # models
            if map["models"].include?(',')
              map["models"].split(',').each { |model| 
                name = model.strip     
                self.models[name] = [] if !self.models[name]
                self.models[name] << feature
              }
            else
              name = map["models"]
              self.models[name] = [] if !self.models[name]
              self.models[name] << feature
            end
          end
        end
        
      end
      
      # Translate a filename into an array of feature filenames
      # 
      # This is a modified version of mislav/rspactor Inspector#translate
      #
      def translate(file)
        self.heard = file
                
        case file
          when %r:^app/controllers/:
          name = file.sub('_controller.rb', '').sub('app/controllers/', '')
          features = self.controllers[name]
          when %r:^app/models/:
          name = file.sub('.rb', '').sub('app/models/', '')
          features = self.models[name]
          #
          when %r:^app/views/:
          file = file.sub('app/views/', '')
          directory = file.split('/')[0..-2].compact.join('/')
          features = self.controllers[directory]
          when %r:^lib/:
          name = file.sub('.rb', '').sub('lib/', '')
          features = self.models[name]
          when %r:.feature$:
            return [file]
          else
          #
        end
        
        features = [] if !features
        
        return features.collect { |name| "features/#{name}.feature" }

      end
      
      # Run an array of feature files
      def run(features)
                
        # redirect spec output to StringIO
        io = StringIO.new
        
        $stdout, old = io, $stdout
        # refresh the loaded test file
        #$".delete(file)
        #require file

        Bolt::Runners::Cucumber.mother.reload_definitions! if Bolt::Runners::Cucumber.mother and self.heard.match('_steps.rb')
        
        ::Cucumber::Cli::Main.execute(features)

        Bolt::Runners::Cucumber.mother.clear_steps_and_scenarios!
        # read the buffer
        result = io.string.to_s.dup

        $stdout = old
                
        # send buffer to stdout
        puts result
        
        last_three = result.split("\n")[-3..-1].join(' ')
        last_three = last_three.gsub("\e[32m", '').gsub("\e[0m", '').gsub("\e[36m", '').gsub("\e[31m", '') # get ri of the color codes
        
        # sent result to notifier
        notifier.result(features.join(' '), last_three)
        
      end
      
    end
  end
end

# Cucumber hacks

# Load Cucumber requirements
require 'cucumber'
begin
  require 'cucumber/rspec_neuter'
rescue LoadError
  puts '** ERROR: Could not load cucumber/rspec_neuter' if Bolt.verbose?
end
require 'cucumber/cli/main'

module Cucumber #:nodoc:
  module StepMother #:nodoc:
    
    # Clear the step definitions and reload them
    def reload_definitions!
      step_definitions.clear
      Dir['features/step_definitions/*'].map do |f| 
        $".delete(f)
        require "features/step_definitions/#{File.basename(f)}"
      end
    end
    
    # Clear the steps and scenarios to always start fresh
    def clear_steps_and_scenarios!
      steps.clear
      scenarios.clear
    end  
  end
  
  module Cli #:nodoc:
    class Main #:nodoc:

      # Overwritten execute to create a reference for StepMother
      def self.execute(args)
        instance = new(args)
        instance.execute!(@step_mother)
        Bolt::Runners::Cucumber.mother = @step_mother
        instance
      end
      
    end
  end
end