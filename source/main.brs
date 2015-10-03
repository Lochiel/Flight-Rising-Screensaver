' This is a screensaver that uses the numeric UserID to download and display
' Dragons from the website http://www.flightrising.com/
' Locally, it stores the user provided UserID, as well as a list of Dragon ID's
' While the screen saver is running it will download Dragon Images and update it's list of Dragon ID's
' 
' Failures in retrieval of any information will (hopefully) simiply result in displaying an "Error Dragon"

' This entry point is executed when the user chooses the "Custom Settings" option for the screensaver
function RunScreenSaverSettings()
	ScreensaverSettings()
end function

'Called whenever the application is entered, either via screensaver mode or Options mode
function Initialize()
	RegistrySetup()
	SetTheme()
	' Here we set the constants. We have them all in one spot to simplify finding them later
	' Values here are NOT altered by configuration changes or in any way by the program later
	GetGlobalAA().FileSys = CreateObject("roTextureManager")
	GetGlobalAA().delay = 5 'How long should the dragon stay on screen before moving?
	GetGlobalAA().duration = 12 'How many cycles of one dragon before we get a new one?
	'The most likely point of failure is a change in the Flight Rising Website
	'Adjust these variables based on changes to Flight Rising's website
	GetGlobalAA().ImageURLHead = "http://flightrising.com/rendern/350/"
	GetGlobalAA().ImageURLTail = "_350.png"
	GetGlobalAA().LairURLHead = "http://flightrising.com/main.php?p=lair&id="
	GetGlobalAA().LairURLPage = "&page="
	GetGlobalAA().MaxDragonsPerPage = 15
	' Regex functions rely on the format of the web pages served by Flight Rising.
	' Those values can be found in GetDragonList.brs in the following functions:
	'	AskTavernAboutDragons(), DragonsAhead(), GetNameFromUserID()
end function

' This entry point is executed by the Roku when it runs the screen saver
function RunScreenSaver()
	Initialize()
	black=&h000000FF
	delay = GetGlobalAA().delay 'How long should the dragon stay on screen before moving?
	duration = GetGlobalAA().duration 'How many cycles of one dragon before we get a new one?
	
	Registry = CreateObject("roRegistrySection", "Core")
	UserID=Registry.Read("UserID") 'Flight Rising User ID, visible on the Clan Profile page
	
	timer=CreateObject("roTimeSpan")
	screen = CreateObject("roScreen",true)
	screen.SetAlphaEnable(true)
	compositor = CreateObject("roCompositor")
	compositor.SetdrawTo(screen, black)
	
	' Update Dragon List, if it needs to be updated
	' Decide which dragon we are about to display
	' Create and display the dragon
	' Move the dragon around the screen for a bit
	' Remove the dragon and clear the drawing space
	' Repeat
	while true
		DragonList = GetDragonList(UserID)
		Dragon = ChooseQuest(DragonList)
		view_sprite=compositor.NewSprite(0,0, NewDragon(Dragon))
		ChaseDragon(view_sprite, compositor, screen)
		timer.mark()
		i=0
		while i<duration
			if timer.totalseconds() < delay then
				compositor.drawAll()
				screen.swapBuffers()
			else
				if i+1=duration then
					exit while
				end if
				ChaseDragon(view_sprite, compositor, screen)
				timer.mark()
				i=i+1
			end if
		end while
		view_sprite.Remove()
		screen.clear(black)
	end while
end Function

' This will create the Dragon image.
' if DragonsLair is a "roBitmap" then everything is working correctly
' However if it isn't then it is an Error Dragon we'll create an "roBitmap" 
function NewDragon(Dragon) as Object
	DragonsLair = GetDragonsGold(Dragon) 'What is the filename we are displaying?
	print "type(DragonsLair):" + type(DragonsLair)
	if type(DragonsLair) = "roBitmap" then
		return CreateObject("roRegion",DragonsLair,0,0,DragonsLair.GetWidth(),DragonsLair.GetHeight())
	else
		print DragonsLair
		DragonImg = CreateObject("roBitmap",DragonsLair)
		return CreateObject("roRegion",DragonImg,0,0,DragonImg.GetWidth(),DragonImg.GetHeight())
	end if
end function

' Jump the Dragon Around the screen
function ChaseDragon(view_sprite as Object, compositor, screen)
	if type(view_sprite) <> "roSprite" then print "Error: ChaseDragon passed invalid Sprite" : return false
	device = CreateObject("roDeviceInfo").GetDisplaySize()
	width = view_sprite.GetRegion().GetWidth()
	height = view_sprite.GetRegion().GetHeight()
	loc = {x:rnd(device.w-width),y:rnd(device.h-height)}
	view_sprite.MoveTo(loc.x,loc.y)
	compositor.drawAll()
	screen.swapBuffers()
end Function

' This will return the unique ID of the Dragon to be displayed
function ChooseQuest(Dragons)
	print "Choosing a Quest!"
	return Dragons[Rnd(Dragons.Count()-1)]
end Function


' Here we prepare to grab the Dragon's image file from the LRU Cache roTextureManager
' This will return either the roBitmap or a String to an Error Dragon
function GetDragonsGold(Dragon)
	if Dragon = invalid
		return ErrorHandler("Invalid")
	end if
	
	'The most likely point of failure is a change in the Flight Rising file tree
	'Adjust these two variables based on changes to Flight Risings file system
	FlightRisingURLHead = GetGlobalAA().ImageURLHead
	FlightRisingURLTail = GetGlobalAA().ImageURLTail
	FlightRisingURL = FlightRisingURLHead + Dragon + FlightRisingURLTail

	return DragonGetTextureManager(FlightRisingURL)
end function

' Grab the Dragon's image from the LRU Cache roTextureManager
Function DragonGetTextureManager(FlightRisingURL as String)
	print "DragonGetTextureManager("+FlightRisingURL+")"
	FileSys = GetGlobalAA().FileSys
	FileSys.SetMessagePort(CreateObject("roMessagePort"))
	request = CreateObject("roTextureRequest",FlightRisingURL)
	timer = CreateObject("roTimespan")
	
	FileSys.RequestTexture(request)
	
	while timer.totalSeconds() < 5
		msg=wait(50 ,FileSys.GetMessagePort())
		if type(msg) = "roTextureRequestEvent" then
			if msg.GetState() = 3 then
				return msg.GetBitmap()
			else if msg.GetState() > 3 then
				print "TextureManager Error: "+ msg.GetState().toStr()
				return ErrorHandler("NotFound")
			end if
		end if
	end while
	return ErrorHandler("TimedOut")
end Function

function ErrorHandler(Error as String) as String
	DateTime = CreateObject("roDateTime").ToISOString()
	print DateTime + " - Error: "+ Error
	if Error = "TimedOut" then return "pkg:/images/error_HTTPTimedOut.png"
	if Error = "NotFound" then return "pkg:/images/error_DragonNotFound.png"
	if Error = "invalid" then return "pkg:/images/error_InvalidDragon.png"
	return "pkg:/images/error_catchAll.png"
end function
