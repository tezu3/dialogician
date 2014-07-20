# encoding: utf-8
require 'stringio'
require 'dialogician'


login_param = {"username"=>"user", "password"=>"password", "type"=>"ssh"}
target_host = "192.0.2.1"

shell = Dialogician::Shell.new


shell.exec(target_host) do |device|
  device.extend Hitachi::APRESIA
  
  device.dryrun = true
  
  output = StringIO.new
  device.output_io = output
  
  device.login(login_param)
  
  vlans = Array::new
  vlans = device.vlan
  
  device.logout
  
  puts output.string
  
  unless vlans.nil? then
    vlans.flatten.each do |vlan|
      puts "VLAN #{vlan["id"]} is exist !!"
    end
  end
  
end