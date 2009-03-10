require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'tlattr_accessors')

describe ThreadLocalAccessors do

  class Foo
    extend ThreadLocalAccessors
    tlattr_accessor :bar, true
    tlattr_accessor :foo, :baz
  end

  class Bar
    def initialize(value)
      @value = value
    end
  end

  it 'should allow defining multiple attributes at once' do
    x = Foo.new
    [:foo, :foo=, :baz=, :baz].each do |method|
      x.should respond_to(method)
    end
  end

  it "should store values local to the thread" do
    x = Foo.new
    x.baz = 2
    Thread.new do
      x.baz = 3
      Thread.new do
        x.baz = 5
      end.join
      x.baz.should == 3
    end.join
    x.baz.should == 2
  end
  
  it 'should, by default, not return a default value' do
    x = Foo.new
    x.baz = 2
    Thread.new do
      x.baz.should be_nil
    end.join
  end

  it 'should, if told to, use the first value as default for subsequent threads' do
    # Foo#bar is defined with +true+ as last param
    x = Foo.new
    x.bar = 2
    Thread.new do
      x.bar.should == 2
      x.bar = 3
      Thread.new do
        x.bar.should == 2
        x.bar = 5
      end.join
      x.bar.should == 3
    end.join
    x.bar.should == 2
  end

  # This will epically FAIL under JRuby, as JRuby doesn't support finalizers
  it 'should not leak memory' do
    x = Foo.new
    n = 6000
    # create many thread-local values to make sure GC is invoked
    n.times do
      Thread.new do
        x.bar = Bar.new(rand)
      end.join
    end
    hash = x.send :instance_variable_get, '@_tlattr_bar'
    hash.size.should < (n / 2) # it should be a lot lower than n!
  end

end

