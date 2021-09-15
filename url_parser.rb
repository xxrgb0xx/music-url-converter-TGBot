config = YAML.load_file("config.yaml")
$proxy = config["yandex"]["https_proxy"]
$proxy_addr = config["yandex"]["https_proxy_addr"]
$proxy_port = config["yandex"]["https_proxy_port"]
$proxy_user = config["yandex"]["https_proxy_user"]
$proxy_pwd = config["yandex"]["https_proxy_password"]

CurTime = DateTime.now.strftime("%d.%m.%Y %H:%M")

def get_html (uri_arg)
    begin
        uri_arg = URI::parse(uri_arg)
        if $proxy == 'yes' || $proxy == 'true' || $proxy == 'enable'
            doc = URI::open(uri_arg, :proxy_http_basic_authentication => ["http://#{$proxy_addr}:#{$proxy_port}", "#{$proxy_user}", "#{$proxy_pwd}"])
            return Nokogiri::HTML(doc)
        else
            doc = URI::open (uri_arg)
            return Nokogiri::HTML(doc)
        end
    rescue => error
        puts "#{CurTime} - \"#{error}\""
    end
end


