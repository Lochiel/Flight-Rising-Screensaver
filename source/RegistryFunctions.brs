function RegistrySetup()
	RegistrySection = CreateObject("roRegistrySection", "Core")
	if NOT RegistrySection.Exists("UserID") then RegistrySection.Write("UserID", "89302")
	if NOT RegistrySection.Exists("UserName") then RegistrySection.Write("UserName", "Default (BlueHelix)")
	if NOT RegistrySection.Exists("LastUpdate") then RegistrySection.Write("LastUpdate", "2015-09-05T18:01:00.000")
	if NOT RegistrySection.Exists("DragonList") then RegistrySection.Write("DragonList", "")
	if NOT RegistrySection.Exists("NextPage") then RegistrySection.Write("NextPage","1")
	RegistrySection.Flush()
end Function

function SaveDragonList(DragonList as Object, NextPage as String)
	DragonString = ""
	RegistrySection = CreateObject("roRegistrySection", "Core")
	
	for each n in DragonList
		DragonString = DragonString + n + ","
	end for
	
	if NOT RegistrySection.Write("DragonList", DragonString) then return false
	if NOT RegistrySection.Write("NextPage", NextPage) then return false
	return RegistrySection.Flush()
end function

function GetSavedDragonList() as Object
	RegistrySection = CreateObject("roRegistrySection", "Core")
	DragonArray = CreateObject("roArray",0,true)
	DragonList = RegistrySection.Read("DragonList").Tokenize(",")
	for each n in DragonList
		DragonArray.Push(n)
	end for
	return DragonArray
end function

function UpdateDragonList() as Boolean
	RegistrySection = CreateObject("roRegistrySection", "Core")
	timer = CreateObject("roTimespan")
	ReloadDelayInMinutes = 60%
	ReloadDelayInSeconds = ReloadDelayInMinutes * 60%
	SecondsSinceLastReload = abs(timer.GetSecondsToISO8601Date(RegistrySection.Read("LastUpdate")))
	return ReloadDelayInSeconds < SecondsSinceLastReload
end Function

function UpdateLastUpdate()
	RegistrySection = CreateObject("roRegistrySection", "Core")
	DateTime = CreateObject("roDateTime").ToISOString()
	RegistrySection.Write("LastUpdate", DateTime)
	return RegistrySection.Flush()
end function