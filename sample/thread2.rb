# encoding: utf-8
require 'stringio'

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


shell = Dialogician::Shell.new
shell.dryrun = true # Dryrun Mode

user_login_param = {"username"=>"user01", "password"=>"password"}
root_login_param = {"username"=>"root", "password"=>"password"}

target_host1 = "192.0.2.1"
target_host2 = "192.0.2.2"

thread1 = shell.thread(target_host1) do |device|
  
  output = StringIO.new
  device.output_io = output
  
  device.login(user_login_param)
  
  device.cmd("date")
  device.cmd("uname -a")
  device.cmd("id")
  device.cmd("pwd")
  device.cmd("sleep 3")
  device.cmd("date")
  
  device.logout
  
  puts "---"
  puts output.string
end


thread2 = shell.thread(target_host2) do |device|
  
  output = StringIO.new
  device.output_io = output
  
  device.login(root_login_param)
  
  device.cmd("date")
  device.cmd("uname -a")
  device.cmd("id")
  device.cmd("pwd")
  device.cmd("sleep 3")
  device.cmd("date")
  
  device.logout
  
  puts "---"
  puts output.string
end


thread1.join
thread2.join
