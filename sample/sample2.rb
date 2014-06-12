# encoding: utf-8
require 'stringio'

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


shell = Dialogician::Shell.new
shell.dryrun = true # Dryrun Mode

target_host1 = "192.0.2.1"
target_host2 = "192.0.2.2"

shell.exec(target_host1, target_host2) do |device1, device2|
  
  output1 = StringIO.new
  output2 = StringIO.new
  
  device1.output_io = output1
  device2.output_io = output2
  
  device1.login({"username"=>"user01", "password"=>"password"})
  device2.login({"username"=>"root", "password"=>"password"})
  
  device1.cmd("uname -a")
  device2.cmd("uname -a")
  
  device1.cmd("id")
  device2.cmd("id")
  
  device1.cmd("pwd")
  device2.cmd("pwd")
  
  puts "---"
  puts output1.string
  puts "---"
  puts output2.string
end
