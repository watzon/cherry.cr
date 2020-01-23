class HTTP::Client
  def dns_resolver=(value : Durian::Resolver)
    @dns_resolver = value
  end

  def dns_resolver
    @dns_resolver
  end

  def io_socket
    @socket
  end

  def tls_context
    tls rescue nil
  end

  def create_socket(hostname : String)
    return TCPSocket.new hostname, @port, @dns_timeout, @connect_timeout unless resolver = dns_resolver
    return TCPSocket.new hostname, @port, @dns_timeout, @connect_timeout unless resolver.is_a? Durian::Resolver

    TCPSocket.new hostname, @port, @dns_timeout, @connect_timeout
  end

  private def socket
    _socket = @socket
    return _socket if _socket

    begin
      hostname = @host.starts_with?('[') && @host.ends_with?(']') ? @host[1_i32..-2_i32] : @host

      socket = create_socket hostname
      socket.read_timeout = @read_timeout if @read_timeout
      socket.sync = false
      @socket = socket

      {% unless flag? :without_openssl %}
        if _tls = tls_context
          socket = OpenSSL::SSL::Socket::Client.new socket, context: _tls, sync_close: true, hostname: @host
        end
      {% end %}

      @socket = socket
    rescue ex
      @socket.try &.close
      raise ex
    end
  end
end
