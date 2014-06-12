# encoding: utf-8
require 'pty'

module Dialogician
  
  
  class Console
    
    attr_reader :read
    attr_reader :write
    attr_reader :pid
    
    
    def initialize(id)
      @id = id
    end
    
    
    def output_io=(io)
      @output_io = io
    end
    
    
    def output_io
      @output_io
    end
    
    
    def login(login_command)
      info_msg = "ID: #{@id}, EXECUTE_COMMAND: #{login_command.to_s.dump}"
      Dialogician::log.info(info_msg)
      @read, @write, @pid = login_process_spawn(login_command)
    end
    
    
    def logout
      
      begin
        @output_io.print "\n"  if @output_io
      rescue Exception=>ignore
      end
      
      begin
        @read.close
        @write.close
      rescue Exception=>ignore
      end
    end
    
    
    def cmd_pre(options, command_params)
      
      commands = []
      success_pattern = []
      error_pattern = []
      cmd_options = []
      
      [command_params].flatten.each do |param|
        commands << param["command"]
        success_pattern << param["expect"]
        error_pattern << param["error"]
        cmd_options << param["option"]
      end
      
      
      mask_str = Dialogician::config.get("mask_string")
      
      timeout = options["timeout"]
      timeout = Dialogician::config.get("cmd_timeout")  if not timeout.to_s =~ /^\d+$/
      
      
      ret = ""
      
      begin
        ::Timeout.timeout(timeout) do
          loop do
            index, output, match, expect_after = expect([success_pattern, options["expect"]], [error_pattern, options["error"]], timeout)
            
            ret += output
            ret += expect_after
            
            @output_io.print output  if @output_io
            @output_io.print expect_after  if @output_io
            
            
            break  if index == success_pattern.size
            
            if index
              @write.puts commands[index].to_s
              output.sub!(commands[index].to_s, mask_str.to_s)
            end
            
            log_cmd = commands[index]
            log_cmd = mask_str.to_s  if cmd_options[index].kind_of?(Hash) and cmd_options[index]["cmd_echo_off"]
            info_msg = "ID: #{@id}, EXECUTE_COMMAND: #{log_cmd.to_s.dump}"
            info_msg += ", OUTPUT: #{output.to_s.dump}, EXPECT_AFTER: #{expect_after.to_s.dump}, MATCH: #{match.to_s.dump}"
            Dialogician::log.info(info_msg)
            
          end
        end
      rescue ::Timeout::Error=>e
        raise TimeoutError, e.message, e.backtrace
      end
      
      
      return ret, ""
      
    end
    
    
    
    def cmd_pst(command, expect, error, timeout=nil, cmd_echo_off=false, output_echo_off=false)
      
      timeout = Dialogician::config.get("cmd_timeout")  if not timeout.to_s =~ /^\d+$/
      
      @write.puts command.to_s
      index, output, match, expect_after = expect(expect, error, timeout)
      
      mask_str = Dialogician::config.get("mask_string")
      
      ret = ""
      ret += output
      ret += expect_after
      ret.sub!(command.to_s, "")
      ret.sub!(match.to_s, "")
      
      output.sub!(command.to_s, mask_str.to_s)  if cmd_echo_off
      
      @output_io.print output  if @output_io
      @output_io.print expect_after  if @output_io
      
      log_cmd = command
      log_cmd = mask_str  if cmd_echo_off
      info_msg = "ID: #{@id}, EXECUTE_COMMAND: #{log_cmd.to_s.dump}"
      
      if output_echo_off
        ret = ""
        Dialogician::log.info(info_msg)
      else
        info_msg += ", OUTPUT: #{output.to_s.dump}, EXPECT_AFTER: #{expect_after.to_s.dump}, MATCH: #{match.to_s.dump}"
      end
      
      Dialogician::log.info(info_msg)
      
      return ret, match
    end
    
    
    
    def cmd_force(command, cmd_echo_off=false)
      mask_str = Dialogician::config.get("mask_string")
      log_cmd = command
      log_cmd = mask_str  if cmd_echo_off
      info_msg = "ID: #{@id}, EXECUTE_COMMAND: #{log_cmd.to_s.dump}"
      Dialogician::log.info(info_msg)
      
      begin
        @write.puts command.to_s
      rescue Exception=>ignore
      end
      
      return "", ""
      
    end
    
    
    
    private
    def login_process_spawn(login_command)
      ::PTY.spawn(login_command)
    end
    
    
    def expect(p_success, p_error, timeout=nil)
      
      to_regexp = lambda do |pattern|
        
        [pattern].flatten.map do |i|
          
          tmp_refexp = 
          case i
          when String
            Regexp.new(Regexp.quote(i.to_s))
          when Regexp
            i
          else
            Regexp.union
          end
          
        end
        
      end
      
      
      success_pattern = to_regexp.call(p_success)
      error_pattern = to_regexp.call(p_error)
      
      
      @read.expect(Regexp.union(*[success_pattern, error_pattern].flatten), timeout) do |output, match, expect_after|
        
        # Timeout
        if not match
          error_message = "ID: #{@id}, expect timeout. #{timeout.to_s.dump}"
          error_message += "\n#{output}#{expect_after}"
          raise TimeoutError, error_message
        end
        
        
        [error_pattern].flatten.each do |regex|
          if regex.match(match)
            error_message = "ID: #{@id}, expect match error. #{regex.to_s.dump}"
            error_message += "\n#{output}#{expect_after}"
            raise ExpectError, error_message
          end
        end
        
        
        [success_pattern].flatten.each_with_index do |regex, index|
          if regex.match(match)
            return index, output, match, expect_after
          end
        end
        
        
        error_message = "ID: #{@id}, expect unknown error."
        error_message += "\n#{output}#{expect_after}"
        raise ExpectError, error_message
        
      end
      
    end
    
  end
  
end
