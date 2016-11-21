﻿<#

.Synopsis

   Monitor critcal system/application state changes and verbally notify user using windows SpeechSynthesizer 



.DESCRIPTION

   This is a test harness.  You can trigger test messages using the EventCreate command line tool



   # to simulate the beginning of a hang event for notepad.exe:

   eventcreate.exe /T Information /ID 50 /L Application /D ""ProcessName":"notepad","



   # to simulate the end of a hang event fir notepad.exe:

   eventcreate.exe /T Information /ID 51 /L Application /D ""ProcessName":"notepad","



   # to simulate a crash event for notepad.exe:

   eventcreate.exe /T Information /ID 1000 /L Application /D ""ProcessName":"notepad","

#>



$sourceid = 'Assistive'

$classname  = 'Win32_NTLogEvent' 

$query = "SELECT * FROM __InstanceCreationEvent WITHIN 5"

$query += " WHERE TargetInstance isa '" + $classname + "' AND " 

$query += "("

# HangDetector Event (Applocation, EventCreate and 50 or 51)

$eventlog_hang_logfile = 'Application'

$eventlog_hang_sourcename = 'EventCreate'

$eventlog_hang_eventcode_begin = '50'

$eventlog_hang_eventcode_end = '51'

$query += " (TargetInstance.Logfile = '" + $eventlog_hang_logfile + "'"

$query += " AND TargetInstance.SourceName = '" + $eventlog_hang_sourcename + "'"

$query += " AND (TargetInstance.EventCode = '" + $eventlog_hang_eventcode_begin + "' OR TargetInstance.EventCode = '" + $eventlog_hang_eventcode_end + "'))"

# CrashLog Event (System, EventCreate and 1000)

$eventlog_crash_logfile = 'Application'

$eventlog_crash_sourcename = 'Application Error'

$eventlog_crash_eventcode_begin = '1000'

$query += " OR (TargetInstance.Logfile = '" + $eventlog_crash_logfile + "'"

$query += " AND TargetInstance.SourceName = '" + $eventlog_crash_sourcename + "'"

$query += " AND TargetInstance.EventCode = '" + $eventlog_crash_eventcode_begin + "')"

$query += ")"



# create SpeechSynth object

Add-Type -AssemblyName System.speech

$SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer



# Register for specified system event notifications

Register-WmiEvent -SourceIdentifier $sourceid -Query $query



# Loop for specified period of time for testing

$number = 20

$i = 1



do{

    write-host "loop $i of $number"

    sleep  1

    $i++ 



    # enumerate any new events which have occured since last check

    $Events = Get-Event | Where-Object -Property SourceIdentifier -EQ $sourceid 

    foreach ($event in $events) {

        
	#Regex to recognize process names in the windows application logs

        $process = ([regex]"(\w+).exe,").match($event.SourceArgs.newevent.targetinstance.message).Groups[1].Value

        $event_code = $event.SourceArgs.newevent.TargetInstance.EventCode


    


        # if a hang start event

        if ($event_code -eq $eventlog_hang_eventcode_begin) {

            $message = $process + ' entered an unresponsive state.'

        }

 

        # if a hang end event

        if ($event_code -eq $eventlog_hang_eventcode_end) {

            $message = $process + ' returned to a responsive state.'

        }

        # if a crash event

        if ($event_code -eq $eventlog_crash_eventcode_begin) {

            $message = $process + ' crashed and must be restarted.'

        }

 

        # Remove notification event now that necessary information has been extracted

        $event | Remove-Event



        # Print and speak the system information to user

        write-host $message

        $SpeechSynth.Speak($message)

    }  

}

while ($i -le $number)



# Dispose of event subscriptions

Get-EventSubscriber  | Where-Object -Property SourceIdentifier -EQ $sourceid | Unregister-Event



# Dispose of speech object

$SpeechSynth.Dispose()