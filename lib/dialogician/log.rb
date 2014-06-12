# encoding: utf-8

module Dialogician; module Log
  
  class Null
    
    def debug(msg) end
    def info(msg) end
    def warn(msg) end
    def error(msg) end
    
  end
  
  
  class Logger
    
    def initialize(level=nil, io = $stdout, *logger_option)
      require 'logger'
      @log = ::Logger.new(io, logger_option)
      @log.progname = "dialogician"
      
      case level.to_s.downcase
      when /debug/
        @log.level = ::Logger::DEBUG
      when /err/
        @log.level = ::Logger::ERROR
      when /warn/
        @log.level = ::Logger::WARN
      else
        @log.level = ::Logger::INFO
      end
      
      @log.datetime_format = "%Y-%m-%d %H:%M:%D %Z"
      @log.formatter = proc {|severity, datetime, progname, msg| "#{datetime} #{progname} [#{severity}] #{msg}\n"}
      
    end
    
    
    def info(msg)
      @log.info(msg)
    end
    
    
    def warn(msg)
      @log.warn(msg)
    end
    
    
    def error(msg)
      @log.error(msg)
    end
    
    
    def debug(msg)
      @log.debug(msg)
    end
    
  end
  
  
  
  class Log4r
    
    DEFAULT_LOG_CONFIG =<<-'EOS'
log4r_config:
  loggers:
    - name: "dialogician"
      type: "Logger"
      trace: "true"
      outputters:
        - "stdout_outputter"
  outputters:
    - name: "outputter"
      type: "Outputter"
    - name: "stdout_outputter"
      type: "StdoutOutputter"
      formatter:
        name: "default"
        type: "PatternFormatter"
        pattern: "%d %C [%l] %M"
        date_pattern: "%Y-%m-%d %H:%M:%S"
    - name: "date_outputter"
      type: "DateFileOutputter"
      dirname: "/tmp"
      trunc: "false"
      date_pattern: "%Y%m%d"
      formatter:
        name: "default"
        type: "PatternFormatter"
        pattern: "%d %C [%l] %M"
        date_pattern: "%Y-%m-%d %H:%M:%S"
    - name: "syslog_outputter"
      type: "SyslogOutputter"
      facility: 136 # ::Syslog::LOG_LOCAL1
      ident: "dialogician"
      formatter:
        name: "default"
        type: "PatternFormatter"
        pattern: "[%l] %M"
        date_pattern: "%Y-%m-%d %H:%M:%S"
    EOS
    
    
    def initialize(level=nil, yaml_config=DEFAULT_LOG_CONFIG)
      require 'log4r'
      require 'log4r/yamlconfigurator'
      require 'log4r/outputter/datefileoutputter'
      require 'log4r/outputter/syslogoutputter'
      
      ::Log4r::YamlConfigurator.load_yaml_string(yaml_config)
      @log = ::Log4r::Logger["dialogician"]
      
      case level.to_s.downcase
      when /debug/
        @log.level = ::Log4r::DEBUG
      when /err/
        @log.level = ::Log4r::ERROR
      when /warn/
        @log.level = ::Log4r::WARN
      else
        @log.level = ::Log4r::INFO
      end
      
    end
    
    
    def info(msg)
      @log.info(msg)
    end
    
    
    def warn(msg)
      @log.warn(msg)
    end
    
    
    def error(msg)
      @log.error(msg)
    end
    
    
    def debug(msg)
      @log.debug(msg)
    end
    
  end
  
  
end; end
