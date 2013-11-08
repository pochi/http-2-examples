module Http2::Examples
  class Handshake < Thor
    desc "dump", "Communication with http using tcpdump"
    def dump
      before do
        create_server
      end

      tcpdump_catpure do
        send_request
      end

      after do
        close_server
      end
    end

    no_tasks do
      def tcpdump_capture(&block)

      end

      def before
        yield
      end

      def after
        yield
      end

      def create_server
      end

      def close_server
      end
    end
  end
end
