


class OutputParser
  
  
  
  def parse_xml(output, data)
    
    doc = REXML::Document.new(output)
    
    
    doc.elements.each(data["root"]) do |element|
      
      if true
      tmp = element.dup
      element.namespaces.each{|prefix, val| tmp.add_namespace(((prefix == "xmlns")? "" : prefix), val)}
      parse_xml(elem.to_s, data)
      else
        # Refexp Parse
      end
      
    end
    
  end
  
  
  
  def parse(output)
    
    delmit(output, delimiter, terminal).each do |block|
      
    end
    
  end
  
  
  private
  def delmit(output, delimiter, terminal=/(?!)/)
    
    block = []
    
    scan = StringScanner.new(output)
    
    65535.times do |i|
      tmp = scan.scan_unit(delimiter)
      break  if not tmp
      
      block[i] = scan.matched
      
      tmp = scan.scan_unit(terminal)
      tmp = scan.scan_unit(delimiter)  if not tmp
      
      block[i] += (tmp)? tmp : scan.rest
      
      byte = 0
      scan.matched.to_s.each_byte{|data| byte += 1}
      scan.pos = scan.pos - byte
      
    end
    
    
    return block
    
  end
  
  
  
  def brace_to_xml(output)
    
    id = ""
    stack = []
    
    regexp_tag = Regexp.new /(\S+)(?:[ \t]+(.+?))?\s*[{}]/
    regexp_val = Regexp.new /(\S+)(?:[ \s]+(.+))?\s*$/
    
    output.to_s.each_char do |ch|
      
      case ch
      when '{'
        id += ch
        
        id.to_s.each_line do |line|
          
          line.chomp!
          
          if line =~ regexp_tag
            xml_data += "<#{$1}>\n"
            xml_data += $2  if $2
            
            stack.push($1)
          elsif line.to_s.gsub(/[{}]\s*$/, "") =~ regexp_val
            xml_data += "<#{$1}>#{$2}</#{$1}>\n"
          end
          
        end
        
        id = ""
        
      when '}'
        
        id += ch
        
        id.to_s.each_line do |line|
          
          line.chomp!
          
          if line =~ regexp_tag
            xml_data += "<#{$1}>#{$2}</#{$1}>\n"
            xml_data += $2  if $2
          elsif line.to_s.gsub(/[{}]\s*$/, "") =~ regexp_val
            xml_data += "<#{$1}>#{$2}</#{$1}>"
          end
          
        end
        
        tag = stack.pop
        xml_data += "</#{tag}>\n"
        id = ""
        
      else
        id += ch
      end
      
    end
    
  end
  
  
end