# encoding: utf-8
begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


shell = Dialogician::Shell.new
shell.run_level(1) # All Device's Run Level 1

login_param = {"username"=>"user01", "password"=>"password"}
target_host = "192.0.2.1"

shell.exec(target_host) do |device|
  
  device.dryrun_cmd_output(/uname/, "Run Level Test \"uname\"")
  
  device.login(login_param)
  
  # cmd == cmd_lv1
  # Run Level 1 >= Command Level 1  => Exec Command
  puts device.cmd("uname")      #=> Linux
  
  # Run Level 1 < Command Level 2  =>  DryRun
  puts device.cmd_lv2("uname")  #=> Run Level Test "uname"
  
  # Run Level 2 >= Command Level 2  => Exec Command
  device.run_level = 2
  puts device.cmd_lv2("uname")  #=> Linux
  
  # Run Level 10 >= Command Level 2  => Exec Command
  device.run_level = 10
  puts device.cmd_lv2("uname")  #=> Linux
  
  device.logout
  
end
