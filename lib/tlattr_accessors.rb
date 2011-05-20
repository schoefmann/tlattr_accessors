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
          thread_id = Thread.current.object_id
          unless #{ivar}.has_key?(thread_id)
            ObjectSpace.define_finalizer(Thread.current, proc {|id| #{ivar}.delete(thread_id) })
          end
          #{ivar}[thread_id] = val
        end
      }, __FILE__, __LINE__
    end
  end
end
