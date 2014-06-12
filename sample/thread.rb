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
target_host1 = "192.0.2.1"
target_host2 = "192.0.2.2"

threads = shell.thread(target_host1, target_host2) do |device|
  
  output = StringIO.new
  device.output_io = output
  
  device.login(login_param)
  
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


p threads.class #=> Array
threads.each{|th| th.join}

