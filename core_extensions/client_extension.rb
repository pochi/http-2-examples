require "http/2/client"
require "thor/shell"

module HTTP2
  class Client

    alias_method :debug_initialize, :initialize
    def initialize(*args)
      shell.say_status("[Connection]", "Called initialize(*args)", :on_cyan)
      shell.say_status("[Memo]", "newされたときはstateはconnection_headerとなる", :on_red)
      debug_initialize(*args)
      common_log_output
    end

    # Connectionクラスを継承したメソッド
    # まだ接続未済であれば接続フレームを送りにいく
    alias_method :debug_send, :send
    def send(frame)
      shell.say_status("[Connection]", "Called send(frame)", :on_cyan)
      common_log_output(frame)
      unless @state == :connected
        shell.say_status("[Memo]", "CONNECTION_HEADERフレームを送って接続状態にする", :on_red)
      end
      debug_send(frame)
    end

    private
    def common_log_output(frame=nil)
      shell.say_status("[Connection]", "priority: " + DEFAULT_PRIORITY.to_s, :on_cyan)
      shell.say_status("[Connection]", "state: " + @state.to_s, :on_cyan)
      shell.say_status("[Connection]", "stream_id: " + @stream_id.to_s, :on_cyan)
      shell.say_status("[Connection]", "frame: " + frame.inspect, :on_cyan)
    end
  end
end
