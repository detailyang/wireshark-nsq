# wireshark-nsq
nsq protocol dissector for wireshark

# usage
if you make nsq.lua in the your global plugin directory or personal plugin just use as follow:
`````
#choose yourself network device, i test with localhost:4150 on lo0:)
tshark -i lo0 -Y 'nsq' -T fields -e nsq.type -e nsq.content
````
or you can use in the current plugin
````
#choose yourself network device, i test with localhost:4150 on lo0:)
tshark -i lo0 -X lua_script:nsq.lua -Y 'nsq' -T fields -e nsq.type -e nsq.content
````

# notes
only test `PUB` `MPUB` `FIN` `RDY` `IDENTIFY` `heartbeat`, welcome to test another command:)
