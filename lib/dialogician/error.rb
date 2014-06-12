# encoding: utf-8
module Dialogician
  
  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class ExpectError < StandardError; end
  
  
  def self.error_msg(message, e)
    [message, e.class, e.message, e.backtrace.join("\n")].join("\n")
  end
  
end