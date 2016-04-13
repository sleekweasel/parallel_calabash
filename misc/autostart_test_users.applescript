to await for deciseconds on method against failure
	set stage to "entry"
	try
		repeat while (not (run method)) and deciseconds is greater than 0
			set stage to "before delay"
			delay 0.1
			set stage to "after delay"
			set deciseconds to deciseconds - 1
			if deciseconds = 0 then
				set stage to "before dialog"
				display dialog "Timed out: " & failure
				set stage to "after dialog"
			end if
			set stage to "before repeat"
		end repeat
	on error errStr number errorNumber
		error errStr & ", in await's " & stage number errorNumber
	end try
end await

to countRemoteSessionWindows()
	set stage to "entry"
	try
		set stage to "before tell"
		tell application "System Events" to tell application process "Screen Sharing"
			set stage to "before count"
			set wcount to count of (windows whose name does not start with "Screen Sharing" and name is not "")
			set stage to "after count"
			return wcount
		end tell
	on error errStr number errorNumber
		error errStr & ", countRemoteSessionWindows' " & stage number errorNumber
	end try
end countRemoteSessionWindows

script connectAsYourself
	set stage to "start"
	try
		tell application "System Events" to tell application process "Screen Sharing"
			set stage to "log radio"
			log every radio button of every radio group of every window
			set stage to "repeat radio"
			repeat with rbutton in (every radio button of every radio group of every window whose name starts with "Log in as yourself")
				set stage to "click radio"
				click rbutton
				set stage to "log button"
				log every button of every window
				set stage to "repeat button"
				repeat with cbutton in (every button of every window whose name starts with "Connect")
					set stage to "click button"
					click cbutton
					set stage to "click return true"
					return true
				end repeat
				set stage to "end repeat cbutton"
			end repeat
			set stage to "end repeat rbutton"
		end tell
		set stage to "end tell"
		return false
	on error errStr number errorNumber
		error errStr & ", connectAsYourself's " & stage number errorNumber
	end try
end script

script remoteWindowHasAppeared
	set stage to "start"
	try
		set newWindowCount to my countRemoteSessionWindows()
		global originalWindowCount
		return originalWindowCount < newWindowCount
	on error errStr number errorNumber
		error errStr & ", remoteWindowHasAppeared's " & stage number errorNumber
	end try
end script

on startVnc(vncUrl)
	set stage to "start"
	try
		global originalWindowCount
		set stage to "set originalWindowCount"
		set originalWindowCount to my countRemoteSessionWindows()
		set stage to "tell screen sharing"
		tell application "Screen Sharing"
			set stage to "geturl " & vncUrl
			GetURL vncUrl
		end tell
		set stage to "await connect as yourself"
		await for 300 on connectAsYourself against "awaiting connect as yourself dialogue"
		set stage to "await new remote window"
		await for 300 on remoteWindowHasAppeared against "awaiting new remote window"
		set stage to "hide screens"
		tell application "System Events" to set visible of processes whose name begins with "Screen Sharing" to false
		set stage to "end"
	on error errStr number errorNumber
		error errStr & ", startVnc(" & vncUrl & ")'s " & stage number errorNumber
	end try
end startVnc

on config(suffix)
	set stage to "start"
	try
		return do shell script "ruby -le 'puts eval(File.read(ENV[\"HOME\"]+\"/.parallel_calabash.autostart\"))" & suffix & "'"
	on error errStr number errorNumber
		error errStr & ", config(" & suffix & ")'s " & stage number errorNumber
	end try
end config

on configList(suffix)
	set stage to "start"
	try
		return every paragraph in config(suffix)
	on error errStr number errorNumber
		error errStr & ", config(" & suffix & ")'s " & stage number errorNumber
	end try
end configList

on run argv
	set stage to "start"
	try
		set users to configList("[:USERS].map{|s|s.split(\"@\")[0]}")
		set hosts to configList("[:USERS].map{|s|s.split(\"@\")[1] || \"localhost\"}")
		if length of users = 0 then
			display dialog (path to me as text) & " USERS in config is undefined"
		end if
		
		set passw to config("[:PASSWORD]")
		if length of passw = 0 then
			display dialog (path to me as text) & " PASSWORD in config is undefined"
		end if
		
		set vncForward to config("[:VNC_FORWARD]")
		if length of vncForward = 0 then
			set vncForward to "6900"
		end if
		
		set user1 to item 1 of users
		set host1 to item 1 of hosts
		if host1 starts with "localhost" then
			set tryCount to 2 # Lazy me
			repeat
				set stage to "ports " & tryCount
				set portUsed to do shell script "lsof -i -n -P|grep -i listen | grep ':" & vncForward & "'; true" -- force happy exit, or script dies.
				if length of portUsed > 0 then
					exit repeat
				end if
				set sshfwd to "ssh -N -L " & vncForward & ":localhost:5900 " & user1 & "@" & host1
				set stage to "forward " & tryCount & " " & sshfwd
				do shell script "( " & sshfwd & " >/tmp/autostart_test_users.forwardfail.err 2>&1 & ) &" -- redirect streams or script hangs!
				delay 1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					display dialog (path to me as text) & " Could not tunnel port " & vncForward & " as " & user1
					exit repeat
				end if
			end repeat
		end if
		
		set stage to "kill screenshare"
		tell application "Screen Sharing" to quit saving no
		set stage to "Activate screenshare"
		activate application "Screen Sharing"
		
		set stage to "vnc"
		repeat with index from 1 to number of items in users
			set iuser to item index of users
			set ihost to item index of hosts
			set stage to "vnc-" & iuser & " @ " & ihost
			set maybeForward to ""
			if ihost starts with "localhost" then
				set maybeForward to ":" & vncForward
			end if
			set stage to "vnc-p-" & iuser & " @ " & ihost
			startVnc("vnc://" & iuser & ":" & passw & "@" & ihost & maybeForward)
			set stage to "vnc-a-" & iuser & " @ " & ihost
		end repeat
	on error eStr number eNum partial result rList from badObj to expectedType
		try
			if eNum = -25211 then -- Rouse privacy stuff
				tell application "System Preferences"
					set securityPane to pane id "com.apple.preference.security"
					tell securityPane to reveal anchor "Privacy_Accessibility"
					activate
				end tell
			else
				display dialog "Caught error after run(" & stage & ") " & eStr & " : " & eNum & " from " & name of badObj & " to " & expectedType & " (partial " & rList & ")"
			end if
		on error eStr2 number eNum2 partial result rList2 from badObj2 to expectedType2
			display dialog "Error while reporting this main error: Caught error after  run(" & stage & ")  " & eStr & " : " & eNum
			display dialog "Secondary error: after DBug=" & DBug & " - " & eStr2 & " : " & eNum2 & " from " & name of badObj2 & " to " & expectedType2 & " (partial " & rList2 & ")"
		end try
	end try
end run
