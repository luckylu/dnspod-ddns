# Dnspod-ddns
#1. Prepare
* Install daemons first through excute `bundle install` 
* Get your own API token from Dnspod 
* Config config.json with your own configuration

#2. Just run it
* `cd lib`
* Excute `god -c ddns.god`
* we can ask it to run foreground with -D: `god -c ddns.god -D`
* Check the log file for more information