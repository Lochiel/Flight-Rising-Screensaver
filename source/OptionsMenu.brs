Function ScreensaverSettings()
	Initialize()
	Theme = CreateObject("roAppManager")
	print "Loading Settings Menu"
	Canvas = CreateObject("roImageCanvas")
	Canvas.SetLayer(0, {color:"#dedacf"})
	Canvas.Show()
	while true
		msg = CreateDisplay()
		if msg = "exit" then
			return true
		else if msg = "ResetDefaults" then
			ResetDefaults()
		else if msg = "UpdateID" then
			input = AcceptNewUserID()
			if input <> invalid then ProcessNewUserID(input)
		end if
	end while
end function

'This sets the theme for the application. Only applicable for the Options menu
'See the "roAppManager" SDK documentation for details
sub SetTheme()
	tan = "#daa37c"
	red = "#731d08"
	Dark_tan = "#b0734f"
	grey = "#dedacf"
	FlightRisingTheme = {
		' Multi-Screen Elements
		BackgroundColor : grey,
		
		' Dialog Screen Elements
		ButtonHighlightColor : tan,
		ButtonMenuHighlightText : red,
		ButtonMenuNormalOverlayText : red,
		ButtonMenuNormalText : red,
		ButtonNormalColor : Dark_tan,
		DialogBodyText : red,
		DialogTitleText : red
		
		'Keyboard Screen Elements
		
		}
	Theme = CreateObject("roAppManager")
	Theme.SetTheme(FlightRisingTheme)
end sub

function CreateDisplay()
	Dialog = CreateObject("roMessageDialog")
	registry = CreateObject("roRegistrySection", "Core")
	
	Dialog.SetMessagePort(CreateObject("roMessagePort"))
	
	Dialog.SetTitle("Flight Rising Viewer")
	Dialog.SetText("Current UserID: "+registry.Read("UserID"))
	Dialog.SetText("Current Name: "+Registry.Read("UserName"))
	
	Dialog.AddButton(1, "Update UserID")
	Dialog.AddButton(2, "Reset Defaults")
	Dialog.AddButton(3, "Exit")	
	
	Dialog.EnableBackButton(true)
	Dialog.EnableOverlay(true)
	Dialog.Show()
	
	while true
		dlgMsg = wait(0, Dialog.GetMessagePort())
		if type(dlgMsg) = "roMessageDialogEvent" then
			if dlgMsg.isButtonPressed() then
				if dlgMsg.GetIndex() = 3 then
					return "exit"
				else if dlgMsg.GetIndex() = 2 then
					return "ResetDefaults"
				else if dlgMsg.GetIndex() = 1 then
					Return "UpdateID"
				end if
			else if dlgMsg.isScreenClose()
				exit while
			end if
		end if
	end while
end function

function AcceptNewUserID()
	Registry = CreateObject("roRegistrySection","Core")
	Keyboard = CreateObject("roKeyboardScreen")
	Keyboard.SetMessagePort(CreateObject("roMessagePort"))
	Keyboard.SetTitle("Enter Flight Rising UserID")
	Keyboard.SetText(Registry.Read("UserID"))
	Keyboard.SetDisplayText("Enter your numeric Flight Rising User ID found on your Clan Profile Page")
	Keyboard.SetMaxLength(7)
	Keyboard.AddButton(1,"Finished")
	Keyboard.AddButton(2,"Back")
	Keyboard.Show()
	
	while true
		msg = wait(0, Keyboard.GetMessagePort())
		if type(msg) = "roKeyboardScreenEvent" then
			if msg.IsScreenClosed() then 
				return invalid
			else if msg.isButtonPressed() then
				if msg.GetIndex() = 1
					return KeyBoard.GetText()
				else if msg.GetIndex() = 2 then 
					return invalid
				end if
			end if
		end if
	end while
end function

' We don't validate the user's input; we simply tell them what it gives us
' We use the input to grab the User Name from the lair page
' 	as well as the first page worth of dragons
' This allows us to start the screen saver without any delay
function ProcessNewUserID(Input)
	print input
	if input.len() < 1 then return false
	Registry = CreateObject("roRegistrySection", "Core")
	WaitScreen = CreateObject("roOneLineDialog")
	WaitScreen.SetTitle("Getting in from Flight Rising...")
	WaitScreen.ShowBusyAnimation()
	WaitScreen.Show()
	PageText = DownloadLairPage(Input, 1)
	if PageText = invalid then return false
	WaitScreen.SetTitle("Grabbing Player Name...")
	PlayerName = GetUserName(PageText)
	if PlayerName = invalid then PlayerName = "Name Not Found"
	WaitScreen.SetTitle("Generating Initial Dragon List...")
	DragonListArray = AskTavernAboutDragons(PageText)
	
	Registry.Write("UserID", Input)
	Registry.Write("UserName", PlayerName)
	SaveDragonList(DragonListArray, "2")
	Registry.Write("LastUpdate", "2015-09-05T18:01:00.000")
	print "Flushing to Registry"
	return Registry.Flush()
end function

' We reset defaults using the simple expedient of deleting them all
' RegistrySetup then sets them to factory values
function ResetDefaults()
	registry = CreateObject("roRegistrySection", "Core")
	for each n in Registry.GetKeyList()
		Registry.Delete(n)
	end for
	RegistrySetup()
	print "Defaults Reset"
	return true
end function