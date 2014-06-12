# encoding: utf-8

begin
  requrie 'dialogician'
rescue Exception=>ignore
  require_relative "../lib/dialogician.rb"
end

login_param = {"username"=>"user01", "password"=>"password"}
proxy = Dialogician::Proxy.new
target_host = "192.0.2.1"

get_config = lambda do
  config = ""
  shell = Dialogician::Shell.new
  shell.run_level(1)
  shell.exec(target_host) do |device|
    device.extend Cisco::IOS
    device.login(login_param)
    config = device.config
  end
  return config
end


begin
  
  before_config = get_config.call
  
  log_file = File.open("./proxy.log", "w")
  
  proxy.start(target_host, login_param) do |device|
    device.extend Cisco::IOS
    device.output_io = log_file
  end
  
  after_config = get_config.call
  
  
  `diff #{before_config} #{after_config}`
  
rescue Exception=>e
  warn e.class
  warn e
  warn e.backtrace
ensure
  log_file.close
end
