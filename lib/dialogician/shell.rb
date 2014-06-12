# encoding: utf-8

module Dialogician
  
  class Shell
    
    
    def initialize
     Dialogician::log = Dialogician::Log::Null.new
     Dialogician::config = Dialogician::Config.new
      @run_level = 0
    end
    
    
    def run_level(run_level)
      @run_level = run_level
    end
    
    
    def exec(*targets, &blocks)
      
      begin
        devices = [targets].flatten.map {|target| Device.new(target)}
        
        [devices].flatten.each {|device| device.run_level = @run_level}
        
        if devices.size <= 1
          yield devices[0]
        else
          yield devices
        end
        
      ensure
        devices.each {|device| device.logout}
      end
      
    end
    
    
    
    def thread(*targets, &blocks)
      
      threads = [targets].flatten.map do |target|
        
        Thread.new do
          
          device = Device.new(target)
          device.run_level = @run_level
          
          begin
            yield device
          ensure
            device.logout
          end
          
        end
        
      end
      
      
      return threads[0]  if threads.size <= 1
      return threads
      
    end
    
    
  end
  
end
