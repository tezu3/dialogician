# encoding: utf-8
$expect_verbose = false

class IO
  
  EXPECT_BUFFER = 65535
  
  def expect(pat, timeout=600)
    
    e_pattern = (pat.instance_of?(Regexp))? pat : Refexp.new(Refexp.quote(pat.to_s))
    buffer = ""
    result = ""
    match = nil
    
    while true
      
      if !IO.select([self],nil,nil,timeout) or eof? then
        result = buffer
        match = nil
        break
      else
        tmp = readpartial(EXPECT_BUFFER)
        buffer.concat(tmp)
        $stdout.print tmp.to_s  if $expect_verbose
      end
      
      if buffer.index(e_pattern)
        match = e_pattern.match(buffer).to_s
        result = buffer.slice!(0, buffer.index(e_pattern)+match.size)
        break
      end
      
    end
    
    yield result, match, buffer  if block_given?
    return result, match, buffer
    
  end
  
end
