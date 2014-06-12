# encoding: utf-8
require 'monitor'
require 'yaml'
require 'pathname'


module Dialogician
  
  class Config
    
    DEFAULT_MODULE_PATH = Pathname.new("#{File.dirname(__FILE__)}/module/**/*.rb").cleanpath.to_s
    
    DEFAULT_CONFIG = <<-EOS
dryrun_prompt_on: true
cmd_timeout: 600
lock_timeout: 3600
delay_time: 0.1
login_retries: 3
login_interval: 10
relogin_timeout: 600
relogin_interval: 60
mask_string: SECURE_STRING
tmpdir: /tmp
ssh_cmd: "ssh -o 'StrictHostKeyChecking=no' -o 'GlobalKnownHostsFile=/dev/null' -o 'UserKnownHostsFile=/dev/null'"
telnet_cmd: "telnet"
    EOS
    
    
    class ConfigMutex
      include MonitorMixin
    end
    
    
    def initialize(config=nil)
      config = DEFAULT_CONFIG.to_s  if config.to_s.empty?
      @config = YAML.load(config)
      @config["dryrun_output_io"] = $stdout
      @mutex = ConfigMutex.new
      
      
      load_module()
      
    end
    
    
    def get(name)
      return @config[name]
    end
    
    
    def set(name, value)
      @mutex.synchronize do
        @config[name] = value
      end
    end
    
    
    
    private
    
    def load_module
      module_path = []
      module_path << DEFAULT_MODULE_PATH
      module_files = module_path.map{|i| Dir.glob(i)}
      
      [module_files].flatten.each do |file|
        next  if not File.exist?(file.to_s)
        
        begin
          require file
        rescue Exception=>e
          warn e
          warn e.class
          warn e.backtrace
        end
        
      end
      
    end
    
    
  end
  
end