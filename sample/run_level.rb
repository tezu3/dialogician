# encoding: utf-8
begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


shell = Dialogician::Shell.new
shell.run_level(0) # All Device's Run Level 0 => DryRun

login_param = {"username"=>"user01", "password"=>"password"}
target_host = "192.0.2.1"

shell.exec(target_host) do |device|
  
  device.dryrun_cmd_output("id", "uid=XXX(user01) ....")
  device.dryrun_cmd_output(/uname/, "Run Level Test \"uname\"")
  
  device.login(login_param)
  
  
  puts device.cmd("id")        #=> uid=XXX(user01) ....
  puts device.cmd("uname -a")  #=> Run Level Test "uname"
  puts device.cmd("uname")     #=> Run Level Test "uname"
  
  
  device.cmd("exit")
  device.logout
  
end
