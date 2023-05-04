class Server
  def initialize(host, port, db_connector)
    @server = TCPServer.new(host, port)
    @db = db_connector
    @client, @request, @request_body, @response = nil
    @headers = {}
  end

  attr_reader :server, :db
  attr_accessor :client, :request, :headers, :request_body, :response

  def start
    loop do
      accept_client
      get_request
      fetch_headers
      fetch_request_body
      prepare_response
      send_response
      client.close
    end
  end

  private

  def accept_client
    self.client = server.accept
  end

  def get_request
    self.request = client.gets.chomp
  end

  def fetch_headers
    while (line = client.gets.chomp)
      break if line.empty?

      key, value = line.split(': ')
      headers[key] = value
    end
  end

  def fetch_request_body
    return unless headers['Content-Length']

    content_length = headers['Content-Length'].to_i
    self.request_body = client.read(content_length)
  end

  def prepare_response
    self.response = access_token_is_valid? ? build_valid_response : build_invalid_response
  end

  def access_token_is_valid?
    request_token = JSON.parse(request_body)["api_token"]
    request_token == ENV.fetch("ACCESS_KEY").to_s
  end

  def build_valid_response
    request_type = request.split.first

    if request_type == "GET"
      response_for_get_request
    elsif request_type == "POST"
      response_for_post_request
    else
      response_for_undefined_request
    end
  end

  def response_for_get_request
    data = db.execute("SELECT item_id, quantity FROM items")
    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n#{data}"
  end

  def response_for_post_request
    item_id = JSON.parse(request_body)["item_id"]
    item_quantity = db.execute("SELECT quantity FROM items WHERE item_id=#{item_id}").first
    item_quantity.nil? ? create_new_item(item_id) : increase_item_quantity(item_id, item_quantity.first)
  end

  def create_new_item(item_id)
    db.execute("INSERT INTO items (item_id, quantity) VALUES (#{item_id}, 1)")
    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\nData are created."
  end

  def increase_item_quantity(item_id, item_quantity)
    db.execute("UPDATE items SET quantity = #{item_quantity += 1} WHERE item_id=#{item_id}")
    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\nData are updated."
  end

  def response_for_undefined_request
    "HTTP/1.1 404 Not Found\r\nContent-Type: text/html."
  end

  def build_invalid_response
    "HTTP/1.1 401 Unauthorized\r\nContent-Type: text/html"
  end

  def send_response
    client.puts response
  end
end
