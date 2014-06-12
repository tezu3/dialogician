# encoding: utf-8
require 'stringio'

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end


login_param = {"username"=>"user", "password"=>"password", "enable_password"=>"cisco", "type"=>"ssh"}
target_host = "192.0.2.1"

shell = Dialogician::Shell.new
shell.dryrun = true # Dryrun Mode

shell.exec(target_host) do |device|
  device.extend Cisco::IOS
  
  output = StringIO.new
  device.output_io = output
  
  device.login(login_param)
  puts device.cmd("show version")
  
  puts "---"
  
  device.reboot(login_param)
  puts = device.cmd("show version")
  
  device.logout
  
  puts "---"
  puts output.string
end
