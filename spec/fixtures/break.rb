RESPONSES[:break] = {
  :header  => [ "Content-Length: 1630", "Content-Type: text/event-plain" ],
  :content => <<-DATA
Event-Name: CHANNEL_EXECUTE
Core-UUID: 8a4da428-37c0-11df-8380-0166d7747984
FreeSWITCH-Hostname: ubuntu
FreeSWITCH-IPv4: 172.16.150.131
FreeSWITCH-IPv6: %3A%3A1
Event-Date-Local: 2010-03-26%2018%3A11%3A13
Event-Date-GMT: Sat,%2027%20Mar%202010%2001%3A11%3A13%20GMT
Event-Date-Timestamp: 1269652273898632
Event-Calling-File: switch_core_session.c
Event-Calling-Function: switch_core_session_exec
Event-Calling-Line-Number: 1823
Channel-State: CS_EXECUTE
Channel-State-Number: 4
Channel-Name: sofia/internal/1000%40172.16.150.131
Unique-ID: 3e19d55a-394f-11df-8485-0166d7747984
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
Caller-Unique-ID: 3e19d55a-394f-11df-8485-0166d7747984
Caller-Source: mod_sofia
Caller-Context: default
Caller-Channel-Name: sofia/internal/1000%40172.16.150.131
Caller-Profile-Index: 1
Caller-Profile-Created-Time: 1269652267394234
Caller-Channel-Created-Time: 1269652267394234
Caller-Channel-Answered-Time: 1269652267509097
Caller-Channel-Progress-Time: 0
Caller-Channel-Progress-Media-Time: 0
Caller-Channel-Hangup-Time: 0
Caller-Channel-Transfer-Time: 0
Caller-Screen-Bit: true
Caller-Privacy-Hide-Name: false
Caller-Privacy-Hide-Number: false
Application: break
DATA
}
