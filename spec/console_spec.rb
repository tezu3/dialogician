# encoding: utf-8
require 'spec_helper'

describe Dialogician::Console do
  
  before do 
    Dialogician::log = Dialogician::Log::Null.new 
    Dialogician::config = Dialogician::Config.new
    @console = Dialogician::Console.new("192.0.2.1")
    @console.stub(:login_process_spawn).and_return(@read, @write, @pid)
  end
  
  
  it 'login: log message' do
    login_command = "ssh root@192.0.2.1"
    
    stdout = capture_stdout do
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      @console.login(login_command)
    end
    
    expect(stdout).to match(login_command)
  end
  
  
  it 'cmd_pre success' do
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/},
    ]
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "EXPECT2\n"
        sleep 1
        write.print "END\n"
      end
      
      @console.cmd_pre({"expect"=>/END/},command_params)
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command2.*?MATCH:.*EXPECT2/)
  end
  
  
  it 'cmd_pre multi command' do
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/},
    ]
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "EXPECT1\n"
        sleep 1
        write.print "EXPECT2\n"
        sleep 1
        write.print "END\n"
      end
      
      @console.cmd_pre({"expect"=>/END/},command_params)
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command1.*?MATCH:.*?EXPECT1/)
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command2.*?MATCH:.*?EXPECT2/)
  end
  
  
  it 'cmd_pre cmd_echo_off' do
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/, "option"=>{"cmd_echo_off"=>true}},
    ]
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "EXPECT1\n"
        sleep 1
        write.print "EXPECT2\n"
        sleep 1
        write.print "END\n"
      end
      
      @console.cmd_pre({"expect"=>/END/},command_params)
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command1.*?MATCH:.*?EXPECT1/)
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?#{Dialogician::config.get("mask_string")}.*?MATCH:.*?EXPECT2/)
  end
  
  
  it 'cmd_pre error' do
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/},
    ]
    
    
    read,write = IO.pipe
    
    @console.instance_variable_set(:@read, read)
    @console.instance_variable_set(:@write, write)
    
    Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
    
    th = Thread.new do
      write.print "ERROR\n"
      sleep 1
      write.print "END\n"
    end
    
    expect{@console.cmd_pre({"expect"=>/END/, "error"=>/ERROR/},command_params)}.to raise_error(Dialogician::ExpectError, /expect match error/)
    
  end
  
  
  it 'cmd_pre timeout error' do
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/},
    ]
    
    
    read,write = IO.pipe
    
    @console.instance_variable_set(:@read, read)
    @console.instance_variable_set(:@write, write)
    
    Dialogician::config.set("cmd_timeout", 5)
    
    th = Thread.new do
      write.print "EXPECT1\n"
    end
    
    expect{@console.cmd_pre({"expect"=>/END/},command_params)}.to raise_error(Dialogician::TimeoutError)
  end
  
  
  it 'cmd_pre loop input' do
    login_command = "ssh root@192.0.2.1"
    
    command_params = [
      {"command"=>"command1", "expect"=>/EXPECT1/},
      {"command"=>"command2", "expect"=>/EXPECT2/},
    ]
    
    
    read,write = IO.pipe
    
    @console.instance_variable_set(:@read, read)
    @console.instance_variable_set(:@write, write)
    
    Dialogician::config.set("cmd_timeout", 5)
    
    th = Thread.new do
      loop {write.print "EXPECT1n"; sleep 1}
    end
    
    expect{@console.cmd_pre({"expect"=>/END/},command_params)}.to raise_error(Dialogician::TimeoutError)
  end
  
  
  it 'cmd_pst success' do
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "OUTPUT1\n"
        sleep 1
        write.print "EXPECT1\n"
      end
      
      output,match = @console.cmd_pst("command1", /EXPECT1/, /ERROR/, 5)
      
      expect(output.strip).to match("OUTPUT1")
      expect(match).to eql("EXPECT1")
      
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command1.*?MATCH:.*EXPECT1/)
  end
  
  
  it 'cmd_pst error' do
    read,write = IO.pipe
    
    @console.instance_variable_set(:@read, read)
    @console.instance_variable_set(:@write, write)
    
    th = Thread.new do
      write.print "OUTPUT1\n"
      sleep 1
      write.print "ERROR\n"
    end
    
    expect{@console.cmd_pst("command1", /EXPECT1/, /ERROR/, 5)}.to raise_error(Dialogician::ExpectError, /expect match error/)
  end
  
  
  it 'cmd_pst timeout' do
    read,write = IO.pipe
    
    @console.instance_variable_set(:@read, read)
    @console.instance_variable_set(:@write, write)
    
    expect{@console.cmd_pst("command1", /EXPECT1/, /ERROR/, 5)}.to raise_error(Dialogician::TimeoutError)
  end
  
  
  it 'cmd_pst cmd_echo_off' do
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "OUTPUT1\n"
        sleep 1
        write.print "EXPECT1\n"
      end
      
      output,match = @console.cmd_pst("command1", /EXPECT1/, /ERROR/, 5, true)
      
      expect(output.strip).to match("OUTPUT1")
      expect(match).to eql("EXPECT1")
      
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?#{Dialogician::config.get("mask_string")}.*?MATCH:.*EXPECT1/)
  end
  
  
  it 'cmd_pst output_echo_off' do
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "OUTPUT1\n"
        write.print "EXPECT1\n"
      end
      
      output,match = @console.cmd_pst("command1", /EXPECT1/, /ERROR/, 5, false, true)
      
      expect(output.strip).to eql("")
      expect(match).to eql("EXPECT1")
      
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command1/)
    expect(log_stdout).to_not match(/OUTPUT:.*?OUTPUT1/)
  end
  
  
  it 'cmd_force' do
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "OUTPUT1\n"
        write.print "EXPECT1\n"
      end
      
      output,match = @console.cmd_force("command1", false)
      
      expect(output).to eql("")
      expect(match).to eql("")
      
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?command1/)
    
  end
  
  
  it 'cmd_force cmd_echo_off' do
    
    log_stdout = capture_stdout do
      
      read,write = IO.pipe
      
      @console.instance_variable_set(:@read, read)
      @console.instance_variable_set(:@write, write)
      
      Dialogician::log = Dialogician::Log::Logger.new(:debug, $stdout)
      
      th = Thread.new do
        write.print "OUTPUT1\n"
        write.print "EXPECT1\n"
      end
      
      output,match = @console.cmd_force("command1", true)
      
      expect(output).to eql("")
      expect(match).to eql("")
      
    end
    
    expect(log_stdout).to match(/EXECUTE_COMMAND:.*?#{Dialogician::config.get("mask_string")}/)
    
  end
  
end

