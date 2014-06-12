# encoding: utf-8
require 'stringio'

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


shell = Dialogician::Shell.new
shell.dryrun = true # Dryrun Mode

login_param = {"username"=>"user01", "password"=>"password"}
target_host = "192.0.2.1"

shell.exec(target_host) do |device|
  
  output = StringIO.new
  device.output_io = output
  
  device.login(login_param)
  
  device.cmd("uname -a")
  device.cmd("id")
  device.cmd("pwd")
  
  device.input_password("su -", login_param["password"])
  
  device.cmd("id")
  device.cmd("uname -a")
  device.cmd("pwd")
  
  device.cmd("exit")
  
  device.logout
  
  puts "---"
  puts output.string
end
