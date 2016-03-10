God.watch do |w|
  w.name = 'ddns'
  w.start = 'ruby /home/michael/raspberry/dnspod-ddns/lib/ddns.rb'
  w.keepalive
end
