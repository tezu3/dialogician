# encoding: utf-8
require 'spec_helper'

describe Dialogician::Config do
  
  before do
    @config = Dialogician::Config.new
  end
  
  it 'get/set' do
    @config.set("cmd_timeout", 1)
    expect(@config.get("cmd_timeout")).to eql(1)
  end
  
  
  it 'get: unknown parameter value' do
    expect(@config.get("test")).to eql(nil)
  end
  
  
  it 'get: default value' do
    default_config = YAML.load(Dialogician::Config::DEFAULT_CONFIG)
    default_config.each do |name, value|
      expect(@config.get(name)).to eql(value)
    end
  end
  
  
end

