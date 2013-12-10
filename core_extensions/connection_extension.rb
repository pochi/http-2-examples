require "http/2/connection"
require "thor/shell"

module HTTP2
  class Connection


    # データ受信時の処理
    alias_method :debug_receive, :receive
    def receive(data)
      shell.say_status("[Debug]", @state.to_s, :green)
      debug_receive(data)
    end

    # 新しく論理的に接続を作成するところ
    alias_method :debug_new_stream, :new_stream
    def new_stream(priority: DEFAULT_PRIORITY, parent: nil)
      shell.say_status("[Connection]", "Called new_stream(frame)", :on_cyan)
      stream = debug_new_stream(priority: DEFAULT_PRIORITY, parent: nil)
      shell.say_status("[Connection]", "priority: " + DEFAULT_PRIORITY.to_s, :on_cyan)
      shell.say_status("[Connection]", "state: " + @state.to_s, :on_cyan)
      shell.say_status("[Connection]", "stream_id: " + @stream_id.to_s, :on_cyan)
      stream
    end

=begin
    # データ送信時の処理
    alias_method :debug_send, :send
    def send(frame)
      shell.say_status("[Debug]", "Called send(frame)", :yellow)
      shell.say_status("[Debug]", "frame: " + frame.inspect, :green)
      shell.say_status("[Debug]", "state: " + @state.to_s, :green)
      shell.say_status("[Debug]", "stream_id: " + @stream_id.to_s, :green)
      debug_send(frame)
    end

    # フレーム間の設定部分
    alias_method :debug_settings, :settings
    def settings(stream_limit: @stream_limit, window_limit: @window_limit)
      shell.say_status("[Debug]", "Called settings(options)", :yellow)
      shell.say_status("[Before]", "", :green)
      shell.say_status("[Debug]", "payload: " + { settings_max_concurrent_streams: stream_limit }.inspect, :green)
      debug_settings(stream_limit: @stream_limit, window_limit: @window_limit)
    end
=end

    def shell
      @_shell ||= Thor::Shell::Color.new
    end
  end
end
