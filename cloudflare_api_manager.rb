require 'net/https'
require 'uri'
require 'json'
require 'ipaddr'

# Various settings
API_ENDPOINT = 'https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules'.freeze
CLOUDFLARE_USERNAME     = '<your username/email here>'.freeze
CLOUDFLARE_API_KEY      = '<your api key here>'.freeze

# Timeout settings
HTTP_READ_TIMEOUT = 10

# Optional proxy settings
HTTP_PROXY_SERVER   = nil
HTTP_PROXY_PORT     = nil
HTTP_PROXY_USERNAME = nil
HTTP_PROXY_PASSWORD = nil

# Our arguments provides from the command line
command = ARGV[0]

begin
  ip = IPAddr.new(ARGV[1])
rescue StandardError => e
  puts "Error: #{e}"
end

# Exit if parameters are missing or invalid
exit unless %w(ban unban).include?(command) && ip

def send_request(url, data, request_type)
  # Construct our HTTP request
  uri  = URI.parse(url)
  http = Net::HTTP.new(uri.host,
                       uri.port,
                       HTTP_PROXY_SERVER,
                       HTTP_PROXY_PORT,
                       HTTP_PROXY_USERNAME,
                       HTTP_PROXY_PASSWORD)
  http.read_timeout = HTTP_READ_TIMEOUT
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri.request_uri) if request_type == 'POST'
  request = Net::HTTP::Delete.new(uri.request_uri) if request_type == 'DELETE'
  request = Net::HTTP::Get.new(uri.request_uri) if request_type == 'GET'

  # Add headers for authentication
  request['Content-Type'] = 'application/json'
  request['X-Auth-Email'] = CLOUDFLARE_USERNAME
  request['X-Auth-Key']   = CLOUDFLARE_API_KEY

  request.body = data 

  http.request(request)
end

def ban_ip(ip)
  # Construct our payload
  data = {}
  data[:mode] = 'block'
  data[:configuration] = {}
  data[:configuration][:target] = 'ip'
  data[:configuration][:value] = ip
  data[:notes] = 'Added by Fail2Ban'

  # Perform the POST
  send_request(API_ENDPOINT, data.to_json, 'POST')
end

def unban_ip(id)
  # Construct our payload
  url = "#{API_ENDPOINT}/#{id}"
  # Perform the DELETE
  send_request(url, nil, 'DELETE')
end

def list_ip(ip)
  data = {}
  data['match'] = 'all'
  data['per_page'] = '1'
  data['configuration.target'] = 'ip'
  data['configuration.value'] = ip

  # build the url suffix instead of sending the data in the body
  # (according to cloudflare api docs)
  url_suffix = "?" 
  for i in data do
    url_suffix << "#{i[0]}=#{i[1]}&"
  end
  url_suffix[..-1]

  send_request("#{API_ENDPOINT}#{url_suffix}", nil, 'GET')
end

if command == 'ban'
  ban_ip(ip) 
elsif command == 'unban'
  begin
    # get the ips rule "id", which is required to delete the firewall rule
    result_hash = JSON.parse(list_ip(ip).body)
    id = result_hash['result'][0]['id']
    unban_ip(id)
  rescue
    puts "no banned ip '#{ip}' found in your cloudflare firewall"
  end
end
