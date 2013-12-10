require "http/2/stream"
require "thor/shell"

module HTTP2
  class Stream
    alias_method :debug_initialize, :initialize
    def initialize(id, priority, window, parend = nil)
      stream = debug_initialize(id, priority, window, parend = nil)
      shell.say_status("[Stream]", "Called initialize(id, priority, window, parend = nil)", :on_yellow)
      common_log_output
      stream
    end

    alias_method :debug_receive, :receive
    def receive(frame)
      debug_receive(frame)
      shell.say_status("[Stream]", "Called receive(frame)", :on_yellow)
      common_log_output
    end

    alias_method :debug_send, :send
    def send(frame)
      shell.say_status("[Stream]", "Called send(frame)", :on_yellow)
      common_log_output(frame)
      debug_send(frame)
    end

    def shell
      @_shell ||= Thor::Shell::Color.new
    end

    private
    def common_log_output(frame=nil)
      shell.say_status("[Stream]", "id: " + @id.inspect, :on_yellow)
      shell.say_status("[Stream]", "state: " + @state.inspect, :on_yellow)
      shell.say_status("[Stream]", "window: " + @window.inspect , :on_yellow)
      shell.say_status("[Stream]", "parent: " + @parent.inspect, :on_yellow)
      shell.say_status("[Stream]", "priority: " + @priority.inspect, :on_yellow)
      shell.say_status("[Stream]", "frame: " + frame.inspect, :on_yellow) if frame
    end
  end
end
