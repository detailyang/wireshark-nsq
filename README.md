# wireshark-nsq
nsq protocol dissector for wireshark

# usage
`````
tshark -i lo0 -Y 'nsq' -T fields -e nsq.type -e nsq.content
````

# notes
only test `PUB` `MPUB` `FIN` `RDY` `IDENTIFY` `heartbeat`, welcome to test another command:)
