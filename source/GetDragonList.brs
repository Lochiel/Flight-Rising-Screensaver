' These functions will download the Lair pages from Flight Rising
' and pull out the Dragon ID Strings
' Know Bugs
' AsyncGetToString() has a character limit that is smaller than the Lair Pages
' Replace with AsyncGetToFile() and ReadAsciiFile()

' If the dragon list is old, update. Otherwise, don't.
Function GetDragonList(UserID as String)
	if UpdateDragonList() then return GetUpdatedDragonList(UserID) else return GetSavedDragonList()
end Function

' We update one page at a time. This allows us to spread our calls to the server out
' This will update the Dragon List by overwriting the part of the array dedicated to the current page
Function GetUpdatedDragonList(UserID as String) as Object
	DragonArray = GetSavedDragonList()
	Registry = CreateObject("roRegistrySection", "Core")
	NextPage = Registry.Read("NextPage").toInt()
	LairPage = DownLoadLairPage(UserID, NextPage) ' Download the lair page
	Dragons = AskTavernAboutDragons(LairPage) ' get the list of dragons for the lair page
	index = (NextPage-1) * GetGlobalAA().MaxDragonsPerPage ' Set our starting point

	' Move Dragons into the Dragon List
	for each n in Dragons
		if DragonArray[index] = invalid then
			DragonArray.Push(n)
		else
			DragonArray[index] = n
		end if
		index = index+1
	end for
	
	' Figure out what page we will look at next time
	if DragonsAhead(LairPage) then 
		NextPage=NextPage+1
	else 
		NextPage=1
		UpdateLastUpdate()
	end if
	
	' If there are missing dragons, fill in the missing spots in order to avoid issues later
	if NextPage <> 1 then
		while DragonArray.Count()-1 <= (NextPage-1) * GetGlobalAA().MaxDragonsPerPage
			DragonArray.Push(DragonArray[rnd(DragonArray.count()-1)])
		end while
	end if
	SaveDragonList(DragonArray, NextPage.toStr())
	return DragonArray
end Function

' Simply download the lair page to a string
Function DownloadLairPage(UserID as String, PgNum as Integer)
	FlightRisingURLHead = GetGlobalAA().LairURLHead
	FlightRisingURLPage = GetGlobalAA().LairURLPage
	http = CreateObject("roUrlTransfer")
	http.SetMessagePort(CreateObject("roMessagePort"))
	http.SetUrl(FlightRisingURLHead + UserID + FlightRisingURLPage + PgNum.toStr())
	http.AsyncGetToString()
	timer=CreateObject("roTimeSpan")
	while timer.totalSeconds() < 5
		msg = wait(0, http.GetPort())
		if (type(msg) = "roUrlEvent") then
			code = msg.GetResponseCode()
			if code = 200 then
				print "Got the page: "+http.GetUrl()
				return msg.GetString()
			else 
				print code
				return invalid
			end if
		end if
	end while
end Function
	
' Generate a list of dragons from the downloaded lair page
Function AskTavernAboutDragons(TextFile as String)
	RegexMatchDragons = CreateObject("roRegex", "class=.dragonthmb. src=""\/rendern\/avatars\/([0-9\/]+)\.png", "")
	RegexSplit = CreateObject("roRegex", "<img", "")
	SplitResults = RegexSplit.Split(TextFile)
	MatchResults = CreateObject("roArray",0,true)
	SplitResults.ResetIndex()
	x = SplitResults.GetIndex()
	while x <> invalid
		result = RegexMatchDragons.Match(x)
		if result[0] <> invalid then
			MatchResults.Push(result[1])
		end if
		x = SplitResults.GetIndex()
	end while
	return MatchResults
end Function

' Find out if there are additional pages
Function DragonsAhead(TextFile)
	RegexMatchMoreDragons = CreateObject("roRegex", "src=\.\/images\/layout\/arrow_right\.png", "")
	x = RegexMatchMoreDragons.Match(TextFile)
	if x[0]=invalid
		return false
	else
		return true
	end if
end Function

' Get the user's name based on the downloaded lair page
Function GetUserName(TextFile as String)
	RegexMatchName = CreateObject("roRegex", "(\w+): <a href=.main\.php\?p=lair&tab=userpage&id=", "")
	Name = RegexMatchName.Match(TextFile)
	return name[1]
end Function
	