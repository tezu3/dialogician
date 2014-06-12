# encoding: utf-8
require 'dialogician/console'
require 'dialogician/device'
require 'dialogician/error'
require 'dialogician/expect'
require 'dialogician/shell'
require 'dialogician/proxy'
require 'dialogician/log'
require 'dialogician/config'

module Dialogician
  class << self
    attr_accessor :log
    attr_accessor :config
  end
end
