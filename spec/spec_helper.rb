# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dialogician'


RSpec.configure do |conf|
  conf.color_enabled = true
  conf.full_backtrace = true
end


def capture_stdout
  require 'stringio'
  old_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end