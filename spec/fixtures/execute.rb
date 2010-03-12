RESPONSES[:execute] = {
  :header  => [ "Content-Length: 1630", "Content-Type: text/event-plain" ],
  :content => <<-DATA
Event-Name: CHANNEL_EXECUTE
Core-UUID: 0be3fbde-2cba-11df-94af-1b000cb72781
FreeSWITCH-Hostname: ubuntu
FreeSWITCH-IPv4: 172.16.150.131
FreeSWITCH-IPv6: %3A%3A1
Event-Date-Local: 2010-03-11%2008%3A12%3A05
Event-Date-GMT: Thu,%2011%20Mar%202010%2016%3A12%3A05%20GMT
Event-Date-Timestamp: 1268323925328573
Event-Calling-File: switch_core_session.c
Event-Calling-Function: switch_core_session_exec
Event-Calling-Line-Number: 1803
Channel-State: CS_EXECUTE
Channel-State-Number: 4
Channel-Name: sofia/internal/1000%40172.16.150.131
Unique-ID: 2cf9f510-2db1-11df-95b7-1b000cb72781
Call-Direction: inbound
Presence-Call-Direction: inbound
Channel-Presence-ID: 1000%40172.16.150.131
Answer-State: answered
Channel-Read-Codec-Name: GSM
Channel-Read-Codec-Rate: 8000
Channel-Write-Codec-Name: GSM
Channel-Write-Codec-Rate: 8000
Caller-Username: 1000
Caller-Dialplan: XML
Caller-Caller-ID-Name: FreeSWITCH
Caller-Caller-ID-Number: 1000
Caller-Network-Addr: 172.16.150.1
Caller-ANI: 1000
Caller-Destination-Number: 502
Caller-Unique-ID: 2cf9f510-2db1-11df-95b7-1b000cb72781
Caller-Source: mod_sofia
Caller-Context: default
Caller-Channel-Name: sofia/internal/1000%40172.16.150.131
Caller-Profile-Index: 1
Caller-Profile-Created-Time: 1268323925227630
Caller-Channel-Created-Time: 1268323925227630
Caller-Channel-Answered-Time: 1268323925298055
Caller-Channel-Progress-Time: 0
Caller-Channel-Progress-Media-Time: 0
Caller-Channel-Hangup-Time: 0
Caller-Channel-Transfer-Time: 0
Caller-Screen-Bit: true
Caller-Privacy-Hide-Name: false
Caller-Privacy-Hide-Number: false
Application: speak
Application-Data: Hello%20world
DATA
}
