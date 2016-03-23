to countActiveSharedScreens()
	local titleCount
	set titleCount to 0
	tell application "System Events" to tell application process "Screen Sharing"
		#	CanÕt make name of every window of Çclass pcapÈ "Screen Sharing" of application "System Events" into type Unicode text. (-1700)
		set windowCount to count of windows
		if windowCount = 0 then
			set titles to {}
		else
			set titles to name of every window -- not title...?!
		end if
		repeat with titleValue in titles
			if titleValue does not start with "Screen Sharing" then
				set titleCount to titleCount + 1
			end if
		end repeat
	end tell
	return titleCount
end countActiveSharedScreens

on startVnc(vncUrl)
	local originalWindowCount
	local tryCount
	#	display dialog "in geturl"
	tell application "Screen Sharing"
		GetURL vncUrl
	end tell
	#	display dialog "out geturl"
	tell application "System Events"
		tell application process "Screen Sharing"
			set originalWindowCount to my countActiveSharedScreens()
			set tryCount to 300 # 30 seconds
			#			display dialog "in await sharing"
			repeat until exists window "Screen Sharing"
				delay 0.1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					display dialog "Timed out waiting for 'Screen Sharing' connection dialogue for " & vncUrl
					exit repeat
				end if
			end repeat
			#			display dialog "out await sharing"
			tell window "Screen Sharing"
				click radio button 2 of radio group 1
				click button 2
			end tell
			set tryCount to 300 # 30 seconds' wait for shared screen to appear.
			#			display dialog "in await screen"
			repeat while (exists window "Screen Sharing") or (my countActiveSharedScreens() = originalWindowCount)
				delay 0.1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					display dialog "Timed out waiting for " & vncUrl & " original window count = " & originalWindowCount & " current = " & my countActiveSharedScreens()
					exit repeat
				end if
			end repeat
			#			display dialog "out await screen"
		end tell
		-- Gotta hide 'em all.
		tell application "System Events" to set visible of processes whose name begins with "Screen Sharing" to false
	end tell
end startVnc

on config(suffix)
	return do shell script "ruby -le 'puts eval(File.read(ENV[\"HOME\"]+\"/.parallel_calabash.autostart\"))" & suffix & "'"
end config

on configList(suffix)
	return every paragraph in config(suffix)
end configList

on run argv
	local DBug
	try
		set DBug to "params"
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
				set DBug to "ports " & tryCount
				set portUsed to do shell script "lsof -i -P|grep -i listen | grep ':" & vncForward & "'; true" -- force happy exit, or script dies.
				if length of portUsed > 0 then
					exit repeat
				end if
				set ssh to "( ssh -N -L " & vncForward & ":localhost:5900 " & user1 & "@" & host1
				set DBug to "forward " & tryCount & " " & ssh
				do shell script "( ssh -N -L " & vncForward & ":localhost:5900 " & user1 & "@" & host1 & " >/dev/null 2>&1 & ) &" -- redirect streams or script hangs!
				delay 1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					display dialog (path to me as text) & " Could not tunnel port as " & user1
					exit repeat
				end if
			end repeat
		end if
		
		set DBug to "vnc"
		repeat with index from 1 to number of items in userList
			set iuser to item index of users
			set ihost to item index of hosts
			set DBug to "vnc-" & iuser & " @ " & ihost
			set maybeForward to ""
			if ihost starts with "localhost" then
				set maybeForward to ":" & vncForward
			end if
			startVnc("vnc://" & iuser & ":" & passw & "@" & ihost & maybeForward)
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
				display dialog "Caught error after DBug=" & DBug & " - " & eStr & " : " & eNum & " from " & name of badObj & " to " & expectedType & " (partial " & rList & ")"
			end if
		on error eStr2 number eNum2 partial result rList2 from badObj2 to expectedType2
			display dialog "Error while reporting this main error: Caught error after DBug=" & DBug & " - " & eStr & " : " & eNum
			display dialog "Secondary error: after DBug=" & DBug & " - " & eStr2 & " : " & eNum2 & " from " & name of badObj2 & " to " & expectedType2 & " (partial " & rList2 & ")"
		end try
	end try
end run
