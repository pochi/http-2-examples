require "http/2/stream"
require "thor/shell"

module HTTP2
  class Stream
    alias_method :debug_initialize, :initialize
    def initialize(id, priority, window, parend = nil)
      stream = debug_initialize(id, priority, window, parend = nil)
      shell.say_status("[Stream]", "Called initialize(id, priority, window, parend = nil)", :on_yellow)
      shell.say_status("[Stream]", "id: " + @id.inspect, :on_yellow)
      shell.say_status("[Stream]", "state: " + @state.inspect, :on_yellow)
      shell.say_status("[Stream]", "window: " + @window.inspect , :on_yellow)
      shell.say_status("[Stream]", "parent: " + @parent.inspect, :on_yellow)
      shell.say_status("[Stream]", "priority: " + @priority.inspect, :on_yellow)
      stream
    end

    def shell
      @_shell ||= Thor::Shell::Color.new
    end
  end
end
