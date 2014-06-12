# encoding: utf-8

module Linux; module CentOS
  
  attr_accessor :sudo_cmd
  
  def login_expand(login_param)
    login_param ||={}
    tmout = login_param["tmout"]
    tmout = 600  if not tmout.to_s =~ /^\d+$/
    cmd("export TMOUT=#{tmout}")
    super(login_param)
    @sudo_cmd = ""
  end
  
  
  def reboot(login_param)
    cmd_force("shutdown -r now", {"success"=>/.*/})
    cmd_force("")
    relogin(login_param)
  end
  
  
  def cmd(command, options={})
    command = "#{@sudo_cmd.to_s.strip} #{command}"  if not @sudo_cmd.to_s.empty?
    output = super("#{command}", options)
    status = super("echo $?")
    status = $1  if status.to_s =~/^-?(\d+)$/
    return {"output"=>output, "exit_status"=>status}
  end
  
  
end; end
