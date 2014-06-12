# encoding: utf-8

module Juniper; module Ex
  
  
  def pattern_success
    return /^(\S+@\S+)?[#>%] ?$/
  end
  
  
  def pattern_error
    
    pattern_error = [
      /unknown command/,
      /syntax error/,
      /missing argument/,
      /invalid value/,
      /error:/
    ]
    
    return pattern_error
  end
  
  
  def login_expand(login_param)
    cmd("cli", {:error=>Dialogician::Device::IGNORE_ERROR})
    cmd("set cli screen-length 0")
    cmd("set cli screen-witdh 0")
    cmd("set cli timestamp format '%Y-%m-%d-%T'")
    super(login_param)
  end
  
  
  def logout_expand(logout_param)
    cmd("exit configuration-mode", {:error=>Dialogician::Device::IGNORE_ERROR})
    super(logout_param)
  end
  
  
  def save()
    cmd("commit check")
    cmd("show | compare")
    cmd("commit")
  end
  
  
  def reboot(login_param)
    cmd("exit configuration-mode", {:error=>Dialogician::Device::IGNORE_ERROR})
    cmd("request system reboot", {"success"=>["yes/no", "confirm"]})
    cmd_force("yes")
    relogin(login_param)
  end
  
  
  def config
    return cmd("show configratuion | display set | no-more")
  end
  
end; end
