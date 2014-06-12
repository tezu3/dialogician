# encoding: utf-8
require 'io/console'
require 'stringio'

module Dialogician
  
  class Proxy
    
    
    def start(target, login_opt)
      
      output_io = $stdout
      
      device = Device.new(target)
      device.run_level = 99
      yield device  if block_given?
      
      
      th = Thread.new do
        
        login_output_io = StringIO.new
        tmp_output_io = device.output_io
        device.output_io = login_output_io
        
        device.login(login_opt)
        
        device.output_io = tmp_output_io
        
        output_io.print login_output_io.string
        device.output_io.print login_output_io.string  if device.output_io
        
        loop do
          
          begin
            output = device.console.read.readpartial(65535)
            output_io.print output
            device.output_io.print output  if device.output_io
          rescue Exception=>ignore
            break
          end
          
        end
        
      end
      
      
      begin
        
        loop do
          ch = nil
          
          STDIN.raw do |raw_io|
            raw_io.noecho do |io|
              ch = io.getch
            end
          end
          
          begin
            device.console.write.print ch  if device.console.write
          rescue Exception=>ignore
          end
          
          break  if not th.status
        end
        
      ensure
        device.logout
      end
      
    end
    
    
  end
  
  
end
