# encoding: utf-8
require 'spec_helper'

describe Dialogician::Device do
  
  before do 
    @dryrun_output = StringIO.new
    #Dialogician::log = Dialogician::Log::Null.new
    Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
    Dialogician::config = Dialogician::Config.new
    Dialogician::config.set("dryrun_output_io", @dryrun_output)
    @device = Dialogician::Device.new("192.0.2.1")
  end
  
  after do
    puts @dryrun_output.string
  end
  
  
  context "Run" do
    
    it 'cmd' do
      command = "command1"
      
      expect = @device.pattern_success
      error = @device.pattern_error
      timeout = nil
      cmd_echo_off = nil
      output_echo_off = nil
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_pst).with(command, expect, error, timeout, cmd_echo_off, output_echo_off).and_return(["OUTPUT", "MATCH"])
      output = @device.cmd(command)
      
      expect(output).to match("OUTPUT")
      expect(@device.last_match).to match("MATCH")
    end
    
    
    it 'cmd expect/error' do
      command = "command1"
      expect = /SUCCESS/
      error = /ERROR/
      timeout = nil
      cmd_echo_off = nil
      output_echo_off = nil
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_pst).with(command, expect, error, timeout, cmd_echo_off, output_echo_off).and_return(["OUTPUT", "MATCH"])
      output = @device.cmd(command, {"success"=>expect, "error"=>error})
      
      expect(output).to match("OUTPUT")
      expect(@device.last_match).to match("MATCH")
    end
    
    
    it 'cmd timeout' do
      command = "command1"
      expect = @device.pattern_success
      error = @device.pattern_error
      timeout = 10
      cmd_echo_off = nil
      output_echo_off = nil
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_pst).with(command, expect, error, timeout, cmd_echo_off, output_echo_off).and_return(["OUTPUT", "MATCH"])
      output = @device.cmd(command, {"timeout"=>10})
      
      expect(output).to match("OUTPUT")
      expect(@device.last_match).to match("MATCH")
    end
    
    
    it 'cmd cmd_echo_off' do
      command = "command1"
      expect = @device.pattern_success
      error = @device.pattern_error
      timeout = nil
      cmd_echo_off = true
      output_echo_off = nil
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_pst).with(command, expect, error, timeout, cmd_echo_off, output_echo_off).and_return(["OUTPUT", "MATCH"])
      output = @device.cmd(command, {"cmd_echo_off"=>true})
      
      expect(output).to match("OUTPUT")
      expect(@device.last_match).to match("MATCH")
    end
    
    
    it 'cmd output_echo_off' do
      command = "command1"
      expect = @device.pattern_success
      error = @device.pattern_error
      timeout = nil
      cmd_echo_off = nil
      output_echo_off = true
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_pst).with(command, expect, error, timeout, cmd_echo_off, output_echo_off).and_return(["OUTPUT", "MATCH"])
      output = @device.cmd(command, {"output_echo_off"=>true})
      
      expect(output).to match("OUTPUT")
      expect(@device.last_match).to match("MATCH")
    end
    
    
    it 'cmd force' do
      command = "command1"
      cmd_echo_off = nil
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_force).with(command, cmd_echo_off)
      output = @device.cmd(command, {"force"=>true})
      
      expect(output).to match("")
      expect(@device.last_match).to match("")
    end
    
    
    it 'cmd force cmd_echo_off' do
      command = "command1"
      cmd_echo_off = true
      
      @device.dryrun = false
      
      @device.console.should_receive(:cmd_force).with(command, cmd_echo_off)
      output = @device.cmd(command, {"force"=>true, "cmd_echo_off"=>true})
      
      expect(output).to match("")
      expect(@device.last_match).to match("")
    end
    
  end
  
  
  context "DryRun" do
    
    it 'cmd' do
      log_stdout = capture_stdout do
        Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
        command = "command1"
        
        @device.dryrun = true
        output = @device.cmd(command)
        
        expect(output).to match("")
        expect(@device.last_match).to match("")
      end
      
      expect(@dryrun_output.string).to match(/command1/)
      expect(log_stdout).to match(/DRYRUN_COMMAND:.*?command1/)
    end
    
    
    it 'cmd cmd_echo_off' do
      log_stdout = capture_stdout do
        Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
        command = "command1"
        
        @device.dryrun = true
        output = @device.cmd(command, {"cmd_echo_off"=>true})
        
        expect(output).to match("")
        expect(@device.last_match).to match("")
      end
      
      expect(@dryrun_output.string).to match(/#{Dialogician::config.get("mask_string")}/)
      expect(log_stdout).to match(/DRYRUN_COMMAND:.*?#{Dialogician::config.get("mask_string")}/)
    end
    
    
    it 'add_dryrun_cmd_output' do
      @device.dryrun = true
      @device.add_dryrun_cmd_output("command1", "OUTPUT1")
      expect(@device.cmd("command1")).to match("OUTPUT1")
      expect(@device.cmd("command")).to match("")
    end
    
    
    it 'add_dryrun_cmd_output regexp' do
      @device.dryrun = true
      @device.add_dryrun_cmd_output(/command/, "OUTPUT")
      expect(@device.cmd("command1")).to match("OUTPUT")
      expect(@device.cmd("command2")).to match("OUTPUT")
      expect(@device.cmd("command3")).to match("OUTPUT")
      expect(@device.cmd("Command")).to match("")
    end
    
    
    it 'add_dryrun_cmd_output  multi command' do
      @device.dryrun = true
      @device.add_dryrun_cmd_output("command1", "OUTPUT1")
      @device.add_dryrun_cmd_output("command2", "OUTPUT2")
      @device.add_dryrun_cmd_output("command3", "OUTPUT3")
      
      expect(@device.cmd("command1")).to match("OUTPUT1")
      expect(@device.cmd("command2")).to match("OUTPUT2")
      expect(@device.cmd("command3")).to match("OUTPUT3")
    end
    
    
    it 'add_dryrun_cmd_output  repeat output' do
      @device.dryrun = true
      @device.add_dryrun_cmd_output("command1", "OUTPUT01")
      @device.add_dryrun_cmd_output("command1", "OUTPUT02")
      @device.add_dryrun_cmd_output("command1", "OUTPUT03")
      
      expect(@device.cmd("command1")).to match("OUTPUT01")
      expect(@device.cmd("command1")).to match("OUTPUT02")
      expect(@device.cmd("command1")).to match("OUTPUT03")
      expect(@device.cmd("command1")).to match("OUTPUT01")
      expect(@device.cmd("command1")).to match("OUTPUT02")
      expect(@device.cmd("command1")).to match("OUTPUT03")
      
      
      @device.add_dryrun_cmd_output("command2", "OUTPUT100")
      
      expect(@device.cmd("command2")).to match("OUTPUT100")
      expect(@device.cmd("command2")).to match("OUTPUT100")
      expect(@device.cmd("command2")).to match("OUTPUT100")
      
      
      @device.add_dryrun_cmd_output("command3", "OUTPUT200")
      expect(@device.cmd("command3")).to match("OUTPUT200")
      
      @device.add_dryrun_cmd_output("command3", "OUTPUT201")
      expect(@device.cmd("command3")).to match("OUTPUT201")
      
      @device.add_dryrun_cmd_output("command3", "OUTPUT202")
      expect(@device.cmd("command3")).to match("OUTPUT202")
    end
    
    
    it 'delete_dryrun_cmd_output  redifine' do
      @device.dryrun = true
      @device.add_dryrun_cmd_output("command1", "OUTPUT1")
      @device.delete_dryrun_cmd_output("command1")
      @device.add_dryrun_cmd_output("command1", "OUTPUT100")
      
      expect(@device.cmd("command1")).to match("OUTPUT100")
      expect(@device.cmd("command1")).to match("OUTPUT100")
      expect(@device.cmd("command1")).to match("OUTPUT100")
    end
    
  end
  
  
  context "login/logout" do
    
    it "login  run" do
      username = "testuser"
      password = "testpassword"
      timeout = Dialogician::config.get("cmd_timeout")
      
      @device.dryrun = true
      @device.console.should_receive(:login).with(@device.send(:create_login_command, {"username"=>username, "password"=>password}))
      @device.console.should_receive(:cmd_pre).with(
        {"expect"=>@device.pattern_success, "timeout"=>timeout},
        [
          {"command"=>username, "expect"=>Dialogician::Device::PATTERN_USERNAME},
          {"command"=>password, "expect"=>Dialogician::Device::PATTERN_PASSWORD, "option"=>{"cmd_echo_off"=>true}}
        ]
      )
      
      @device.dryrun = false
      @device.login({"username"=>username, "password"=>password})
    end
    
    
    it "login  dryrun"
    
    it "login/logout expand"
    
    it "relogin"
    
    it "proxy login"
    
    it "multi proxy login"
    
    it "double login"
    
  end
  
  
  context "retry" do
    
    it "login"
    
    it "cmd"
    
  end
  
  
  context "RunLevel" do
    
    it "cmd_lv*"
    
  end
  
  
  context "Utils" do
    
    it "input_password"
    
    it "cmd_force"
    
    it "lock/unlock"
    
  end
  
  
end

