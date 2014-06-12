# encoding: utf-8

module Cisco; module IOS
  
  
  def pattern_error
    
    pattern_error = [
      /% Unknown command/,
      /% Incomplete command/,
      /% Invalid input/,
      /% Bad passwords/,
      /Command rejected:/
    ]
    
    return pattern_error
  end
  
  
  def login_expand(login_param)
    cmd("terminal length 0")
    cmd("terminal width 0")
    input_password("enable", login_param["enable_password"])
    cmd("terminal no monitor")
    super(login_param)
  end
  
  
  def logout_expand(logout_param)
    cmd("end", {:error=>Dialogician::Device::IGNORE_ERROR})
    super(logout_param)
  end
  
  
  def save()
    cmd("end", {:error=>Dialogician::Device::IGNORE_ERROR})
    cmd("write memory")
  end
  
  
  def reboot(login_param)
    cmd("reload", {"success"=>["yes/no", "confirm"]})
    cmd("y", {"success"=>"confirm"})  if last_match =~ /yes\/no/
    cmd_force("")
    relogin(login_param)
  end
  
  
  def config
    return cmd("show running-config")
  end
  
  
  def change_config?
    running = cmd("show running-config")
    startup = cmd("show startup-config")
    
    (running == startup)? true : false
  end
  
end; end
