# encoding: utf-8

module Hitachi; module APRESIA
  
  
  def pattern_error
    
    pattern_error = [
      /% Ambiguous command/,
      /% Incomplete command/,
      /% Invalid /,
      /% No such /
    ]
    
    return pattern_error
  end
  
  
  def login_expand(login_param)
    cmd("enable")
    cmd("configure terminal")
    cmd("terminal length 0")
    cmd("end")
    super(login_param)
  end
  
  
  def logout_expand(logout_param)
    cmd("conf ter", {:error=>Dialogician::Device::PATTERN_IGNORE})
    cmd("terminal no length")
    cmd("end")
    super(logout_param)
  end
  
  
  def save()
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    cmd("write memory")
  end
  

  def reboot(login_param)
    # TODO: reboot test
  end
  
  
  def config
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    return cmd("show running-config")
  end
  
  
  def change_config?
    running = cmd("show running-config")
    flash = cmd("show flash-config")
    
    (running == flash)? true : false
  end
  
  def system
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    out_system = cmd("show system")
    out_version = cmd("show version")
    
    ret = Hash::new
    
    # TODO: refactoring (scan reduce)
    out_version.scan(/^System Revision(\s)*: ([0-9.]+)/)
    ret["version"] =  $2
    
    out_system.scan(/^Hardware Model(\s)*: (.*)$/)
    ret["model"] = $2
    
    out_system.scan(/^Serial Number(\s)*: ([0-9]+)$/)
    ret["serial"] = $2
    
    return ret
  
  end
  
  
  def mmrp_status
    # TODO: multi VLAN Group (if use)
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    out_mmrp = cmd("show mmrp-plus status")
    
    ret = Array::new
    group = Hash::new

    array_block = out_mmrp.split(/-{2,}/)
    
    return nil if array_block.size < 3
    
    # VLAN Group, Master/Slave VLAN
    array_block[0].to_s.scan(/^VLAN Group(\s)*: ([0-9]+)(.*)Master VLAN(\s)*: ([0-9,-]+)(.*)Slave VLAN(\s)*: ([0-9,-]+)/m)
    group["vlan_group"] =  $2
    group["master_vlan"] = $5
    group["slave_vlan"] = $8
    
      
    group["ports"] = Array::new
    array_port_key = ["port","ring_id","port_mode","port_status_master_vlan","port_status_slave_vlan","ring_name"]
      
    # Port
    array_block[2].each_line do |line|
      line.chomp! unless line.nil?
      line.lstrip! unless line.nil?
      array_port_value = line.split(/\s{2,}/)
      group["ports"] << Hash[*[array_port_key, array_port_value].transpose.flatten] if array_port_value.size == 6
    end
    
    ret << group unless group.nil?
    return ret
    
  end
  
  
  def vlan
    # TODO: refactoring (romove magic number)
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    out_vlan = cmd("show vlan | begin Name")
    array_block = out_vlan.split(/\n\n/)
    return nil if array_block.size < 2
    
    ret = Array::new
    
    array_block[0].each_line do |line|
      next if line.nil?
      array_line = line.to_s.split(/[\s|]+/)
      next if array_line.nil? || array_line.size < 5 || array_line[0].to_s == ""
      
      hash_vlan = Hash::new
      hash_vlan["name"] = array_line[0]
      hash_vlan["id"] = array_line[1]
      hash_vlan["status"] = array_line[2]
        
      hash_vlan["switchport"] = Array::new
      (4..array_line.size - 1).each do |num|
        array_line[num].each_char do |ch|
          hash_vlan["switchport"] << ch
        end
      end
      
      ret << hash_vlan
    end
    
    return ret
      
  end
  
  
  def interface
    cmd("end", {:error=>Dialogician::Device::PATTERN_IGNORE})
    out_interface = cmd("show int status")
    array_block = out_interface.split(/-{20,}/)
    return nil if array_block.size < 2
    
    ret = Array::new
    port = Hash::new
    
    array_block[1].each_line do |line|
      line.chomp!
      next if line.nil?
      line.lstrip!
      next if line.nil?
      line.rstrip!
      
      if /^(?<pt>[\d|\/]+)\s+\[(?<description>.*)\]/ =~ line
        port["name"] = pt
        port["description"] = description.rstrip
      elsif /^(Disable|Down|[\d]+(G|M)\/)/ =~ line
        array_status = line.split(/\s+/)
        case array_status.size
        when 8 then
          port["linkstatus"] = array_status[0]
          port["flowstatus"] = array_status[1]
          port["autoneg"] = array_status[2]
          port["advertise"] = array_status[3]
          port["fix"] = array_status[4]
          port["pause"] = array_status[5]
          port["mdix"] = array_status[6]
          port["media"] = array_status[7]
        when 2 then
          port["linkstatus"] = array_status[0]
          port["flowstatus"] = ""
          port["autoneg"] = ""
          port["advertise"] = ""
          port["fix"] = ""
          port["pause"] = ""
          port["mdix"] = ""
          port["media"] = array_status[1]
        else
          port["linkstatus"] = ""
          port["flowstatus"] = ""
          port["autoneg"] = ""
          port["advertise"] = ""
          port["fix"] = ""
          port["pause"] = ""
          port["mdix"] = ""
          port["media"] = ""
        end
        ret << port.clone
        port.clear
      end
    end
    
    return ret
    
  end
  
end; end
