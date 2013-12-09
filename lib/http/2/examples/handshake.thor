require "thor"
require "systemu"


module Http2
  class Handshake < Thor
    desc "dump", "Communication with http using tcpdump"
    def dump
      before do
        remove_dump_file
        create_server
      end

      tcpdump_capture do
        send_request
      end

      after do
        display_capture
      end
    end

    no_tasks do
      def shell
        Thor::Shell::Color.new
      end

      def tcpdump_capture
        @tcp_process = Thread.fork do
          shell.say_status("[start]", "tcpdump",:green)
          systemu("sudo tcpdump -w handshake.cap -i lo0 port 8080")
        end

        sleep 3
        yield
        sleep 3

        systemu("ps -ef | grep tcpdump")[1].each_line do |line|
          process_id =  line.split(" ")[1]
          systemu("sudo kill -STOP #{process_id}")
        end
      end

      def send_request
        shell.say_status("[start]", "client",:green)
        load File.expand_path(File.dirname(__FILE__) + "/client.rb")
      end

      def remove_dump_file
        systemu("sudo rm handshake.cap")
      end

      def before
        yield
      end

      def after
        @server_thread.kill
        sleep 2
        shell.say_status("[finish]", "tcpdump",:green)
        yield
      end

      def create_server
        @server_thread = Thread.fork do
          shell.say_status("[start]", "server",:green)
          load File.expand_path(File.dirname(__FILE__) + "/server.rb")
        end
      end

      def display_capture
        shell.say_status("[finish]", "you can display tcp capture with 'tcpdump -r handshake.cap'",:green)
      end
    end
  end
end
