# encoding: utf-8
require 'stringio'

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


proxy_login_param = {"username"=>"proxy_user", "password"=>"proxy_password"}
login_param = {"username"=>"user", "password"=>"password", "proxy_login_param"=>proxy_login_param}
target_host = "192.0.2.1"

shell = Dialogician::Shell.new
shell.dryrun = true # Dryrun Mode

shell.exec(target_host) do |device|
  device.extend Linux::CentOS
  
  output = StringIO.new
  device.output_io = output
  
  device.login(login_param)
  result = device.cmd("uname -a")
  
  puts result["exit_status"]
  puts result["output"]
  
  
  device.sudo_cmd = "sudo"
  result = device.cmd("ifconfig")
  
  puts result["exit_status"]
  puts result["output"]
  
  
  device.logout
  
  puts "---"
  puts output.string
end
