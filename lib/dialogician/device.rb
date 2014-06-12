# encoding: utf-8
require 'timeout'


module Dialogician
  
  class Device
    
    PATTERN_CONSOLE = /^.*[#>$] ?$/
    PATTERN_USERNAME = /[Uu]sername: ?$/
    PATTERN_PASSWORD = /[Pp]assword: ?$/
    PATTERN_CONNECTION_CLOSE = /Connection .*closed/
    PATTERN_IGNORE = Regexp.union
    
    
    # Expend Custom Module
    def login_expand(login_param={})
    end
    
    # Expend Custom Module
    def logout_expand(logout_param={})
      logout_msg = PATTERN_CONNECTION_CLOSE
      cmd("exit", {"success"=>logout_msg})
    end
    
    # Expend Custom Module
    def pattern_success
      return PATTERN_CONSOLE
    end
    
    # Expend Custom Module
    def pattern_error
      return PATTERN_IGNORE
    end
    
    
    
    def initialize(id)
      
      @pattern_username = PATTERN_USERNAME
      @pattern_password = PATTERN_PASSWORD
      
      @id = id
      @conn = Dialogician::Console.new(@id)
      @run_level = 10
      @proxy_hop_count = 0
      @dryrun_output_io = Dialogician::config.get("dryrun_output_io")
      @dryrun_output_io.sync = true
      @dryrun_cmd_output = {}
    end
    
    
    def to_s
      return @id
    end
    
    
    def dryrun?
      @run_level <= 0
    end
    
    
    def add_dryrun_cmd_output(cmd, *output)
      @dryrun_cmd_output[cmd] ||= {}
      @dryrun_cmd_output[cmd]["call_times"] ||= 0
      @dryrun_cmd_output[cmd]["output"] ||= []
        
      [output].flatten.each do |output_data|
        @dryrun_cmd_output[cmd]["output"] << output_data
      end
      
    end
    
    
    def delete_dryrun_cmd_output(cmd)
      @dryrun_cmd_output[cmd] = {}
      @dryrun_cmd_output[cmd]["call_times"] = 0
      @dryrun_cmd_output[cmd]["output"] = []
    end
    
    
    def run_level=(run_level)
      @run_level = run_level
      @run_level = 0  if not @run_level.to_s =~ /^\d+$/
    end
    
    
    def dryrun=(flag)
      @run_level = (flag)? 0 : 10
    end
    
    
    def output_io=(io)
      @conn.output_io = io
    end
    
    
    def output_io
      @conn.output_io
    end
    
    
    def console
      return @conn
    end
    
    
    def lock(timeout=nil)
      timeout = Config.get("lock_timeout")  if not lock_timeout.to_s =~ /^\d+$/
      tmpdir = Config.get("tmpdir")
      
      begin
        FileUtils.mkdir_p(tmpdir)
      rescue Exception=>ignore
        tmpdir = Dir.tmpdir
      end  if not File.exists?(tmpdir)
      
      
      ::Timeout.timeout(timeout) do
        lockfile_path = Pathname.new("#{tmpdir}/dialogician_lock_file_#{@id}").cleanpath.to_s
        @lock = open(lockfile_path, "a")
        @lock.flock(File::LOCK_EX)
      end
      
    end
    
    
    def unlock
      return  if not @lock
      @lock.flush
      @lock.flock(File::LOCK_UN)
      @lock.close
      @lock = nil
    end
    
    
    
    def login(login_param)
      
      return 0  if @is_login
      
      login_param ||= {}
      
      username      = login_param["username"]
      password      = login_param["password"]
      retries       = login_param["retries"]
      interval      = login_param["interval"]
      login_timeout = login_param["timeout"]
      
      retries       = Dialogician::config.get("login_retries")   if not retries.to_s       =~ /^\d+$/
      interval      = Dialogician::config.get("login_interval")  if not interval.to_s      =~ /^\d+$/
      login_timeout = Dialogician::config.get("cmd_timeout")     if not login_timeout.to_s =~ /^\d+$/
      
      proxy_login_param = login_param["proxy_login_param"]
      
      
      begin
        
        login_command = create_login_command(login_param)
        
        if proxy_login_param != nil and proxy_login_param.class == Hash
          @proxy_hop_count += 1
          
          login(proxy_login_param)
          
          cmd(login_command, {"success"=>[@pattern_username, @pattern_password, pattern_success]})
          cmd(username)  if last_match.match(@pattern_username)
          cmd(password, {"cmd_echo_off"=>true})  if last_match.match(@pattern_password)
        else
          
          if dryrun?
            cmd_dryrun(login_command)
          else
            @conn.login(login_command)
            @conn.cmd_pre(
              {"expect"=>pattern_success, "timeout"=>login_timeout},
              [
                {"command"=>username, "expect"=>@pattern_username},
                {"command"=>password, "expect"=>@pattern_password, "option"=>{"cmd_echo_off"=>true}}
              ]
            )
          end
          
        end
        
        login_expand(login_param)
        @is_login = true
        
      rescue Exception=>e
        retries -= 1
        
        if retries > 0
          warn_msg = Dialogician::error_msg("login failed. #{@id.to_s.dump}, remain #{retries.to_s.dump} times, wait #{interval.to_s.dump}s", e)
          Dialogician::log.warn(warn_msg)
          wait(interval)
          retry
        else
          error_msg = Dialogician::error_msg("login failed. #{@id.to_s.dump}", e)
          raise e.class, error_msg
        end
        
      end
      
      return 0
      
    end
    
    
    
    def logout(logout_param={})
      
      return 0  if not @is_login
      
      logout_param ||= {}
      
      if @proxy_hop_count > 0
        
        begin
          cmd("exit", {"success"=>PATTERN_CONNECTION_CLOSE})
        rescue Exception=>ignore
        end
        
        @proxy_hop_count -= 1
        
      else
        
        begin
          logout_expand(logout_param)
        rescue Exception=>ignore
        end
        
        
        begin
          @conn.logout
        rescue Exception=>ignore
        end
        
      end
      
      unlock
      @is_login = false
      
      return 0
      
    end
    
    
    
    def relogin(relogin_param={})
      
      @id      = relogin_param["id"]  if relogin_param["id"]
      timeout  = relogin_param["relogin_timeout"]
      interval = relogin_param["relogin_interval"]
      
      
      timeout  = Dialogician::config.get("relogin_timeout")   if not timeout  =~ /^\d+$/
      interval = Dialogician::config.get("relogin_interval")  if not interval =~ /^\d+$/
      
      
      logout()
      
      begin
        ::Timeout.timeout(timeout) do
          loop do
            
            wait(interval)
            
            begin
              login(relogin_param)
              break
            rescue Exception=>e
              warn_msg = Dialogician::error_msg("relogin failed. #{@id.to_s.dump}, wait #{interval.to_s.dump}s", e)
              Dialogician::log.warn(warn_msg)
            end
            
          end
        end
      rescue Exception=>e
        error_msg = Dialogician::error_msg("relogin timeout. #{@id.to_s.dump}, #{timeout.to_s.dump}s", e)
        Dialogician::log.error(warn_msg)
        raise e.class, error_msg
      end
      
      return 0
      
    end
    
    
    def last_match
      @last_match.to_s
    end
    
    
    def input_password(command, password, command_options={}, password_options={})
      
      output = ""
      
      output += cmd(command, command_options.merge({"success"=>[@pattern_password, pattern_success]}))
      
      if last_match.match(@pattern_password)
        output += cmd(password, password_options.merge({"cmd_echo_off"=>true}) )
      end
      
      return output
      
    end
    
    
    
    def cmd(command, options={})
      
      options ||= {}
      
      expect          = options["success"]
      error           = options["error"]
      timeout         = options["timeout"]
      delay_time      = options["delay_time"]
      cmd_echo_off    = options["cmd_echo_off"]
      output_echo_off = options["output_echo_off"]
      run_level       = options["run_level"]
      retries         = options["retries"]
      interval        = options["interval"]
      force           = options["force"]
      
      
      expect = pattern_success  if not expect
      error = pattern_error  if not error
      retries = 1  if not retries.to_s =~ /^\d+$/
      delay_time = Dialogician::config.get("delay_time")  if not delay_time =~ /^\d+$/
      run_level = 1  if not run_level.to_s =~ /^\d+$/
      
      output = ""
      match = ""
      
      begin
        if run_level > @run_level
          output, match = cmd_dryrun(command, run_level, cmd_echo_off)
        elsif force
          @conn.cmd_force(command, cmd_echo_off)
        else
          output, match = @conn.cmd_pst(command, expect, error, timeout, cmd_echo_off, output_echo_off)
        end
      rescue Exception=>e
        retries -= 1
        
        if retries > 0
          warn_msg = Dialogician::error_msg("failed to execute command. #{@id.to_s.dump}, command #{command.to_s.dump}, remain #{retries.to_s.dump} times, wait #{interval.to_s.dump}s", e)
          Dialogician::log.warn(warn_msg)
          wait(interval)
          retry
        else
          error_msg = Dialogician::error_msg("failed to execute command. #{@id.to_s.dump}, command #{command.to_s.dump}", e)
          raise e.class, error_msg
        end
        
      end
      
      
      wait(delay_time)
      
      @last_match = match
      
      return output
    end
    
    
    def cmd_force(command, options={})
      options ||= {}
      options["force"] = true
      cmd(command, options)
    end
    
    
    def method_missing(id ,*args, &block)
      
      if id.to_s =~ /^cmd_lv(\d)$/
        command = args[0]
        options = args[1]
        options = {}  if not options.kind_of?(Hash)
        options["run_level"] = $1
        return cmd(command, options)
      end
      
      super
    end
    
    
    
    private
    
    def create_login_command(login_param)
      username      = login_param["username"]
      login_type    = login_param["type"]
      port          = login_param["port"]
      login_option  = login_param["option"]
      
      if login_type.to_s == "telnet"
        login_command = telnet_cmd = Dialogician::config.get("telnet_cmd")
        login_command += @id.to_s
        login_command += " #{port}" if port =~ /^\d+$/
        login_command += " #{login_option}"  if not login_option.to_s.empty?
      else # ssh
        login_command = ssh_cmd = Dialogician::config.get("ssh_cmd")
        login_command += " -p #{port}"  if port =~ /^\d+$/
        login_command += " #{username}@"  if not username.to_s.empty?
        login_command += @id.to_s
        login_command += " #{login_option}"  if not login_option.to_s.empty?
      end
      
      return login_command
    end
    
    
    def wait(time)
      time = 0  if not time.to_s =~ /^\d+$/
      sleep time  if not dryrun?
    end
    
    
    def cmd_dryrun(command, run_level=0, cmd_echo_off=false)
      mask_str = Dialogician::config.get("mask_string")
      str = command
      str = mask_str  if cmd_echo_off
      str = "#{@id}> #{str}"  if Dialogician::config.get("dryrun_prompt_on")
      @dryrun_output_io.print "#{str}\n"
      
      output = ""
      
      @dryrun_cmd_output.each do |cmd, dryrun_data|
        
        if cmd.kind_of?(Regexp)
          next  if not command.to_s =~ cmd
        else
          next  if not command.to_s == cmd.to_s
        end
        
        next  if not dryrun_data.kind_of?(Hash)
        next  if not dryrun_data["call_times"].to_s =~ /^\d+$/
        next  if not dryrun_data["output"].kind_of?(Array)
        
        call_times = dryrun_data["call_times"].to_s.to_i % dryrun_data["output"].size
        dryrun_data["call_times"] += 1
        output = dryrun_data["output"][call_times]
      end
      
      
      info_msg = "DRYRUN_COMMAND: #{command.to_s.dump}"
      info_msg = "DRYRUN_COMMAND: #{mask_str.to_s.dump}"  if cmd_echo_off
      info_msg += ", RUN_LEVEL: #{run_level}/#{@run_level}"
      info_msg += ", output: #{output.to_s.dump}"
      Dialogician::log.info(info_msg)
      
      return output, ""
    end
    
    
  end # class Device
  
end # moudle Dialogician
