module ThreadLocalAccessors
  # Creates thread-local accessors for the given attribute name.
  #
  # === Example:
  #
  #   tlattr_accessor :my_attr, :another_attr
  #
  # === Default values
  #
  # You can make the attribute inherit the first value that was set on it in
  # any thread:
  #
  #   tlattr_accessor :my_attr, true
  #
  #   def initialize
  #     self.my_attr = "foo"
  #     Thread.new do
  #        puts self.my_attr # => "foo" (instead of nil)
  #     end.join
  #   end
  def tlattr_accessor(*names)
    first_is_default = names.pop if [true, false].include?(names.last)
    names.each do |name|
      ivar = "@_tlattr_#{name}"
      class_eval %Q{
        def #{name}
          if #{ivar}
            #{ivar}[Thread.current.object_id]
          else
            nil
          end
        end

        def #{name}=(val)
          #{ivar} = Hash.new #{'{|h, k| h[k] = val}' if first_is_default} unless #{ivar}
          unless #{ivar}.has_key?(Thread.current)
            finalize = Thread.current.object_id # required for JRuby compatibility
            ObjectSpace.define_finalizer(Thread.current, lambda { #{ivar}.delete(finalize) })
          end
          #{ivar}[Thread.current.object_id] = val
        end
      }, __FILE__, __LINE__
    end
  end
end
