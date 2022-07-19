// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

//Opens a GUI to input chosen launch parameters in a much more user friendly way than parameters.
Function launchParameters {	
	
	//Initialise
	local userInput is false.
	local confirmed is false.
	local gui is gui(375).
	local output is list().
	local inputError is false.
	local warning is false.
	local warningCount is 0.
	local tMin is 0.
	local tSec is 0.
	global launchNode is " ".
	global maxApoapsis is (body:soiradius*0.975)-ship:body:radius.
	global launchLocation is ship:geoposition.							// Records liftoff geo-location for downrange distance calc
	
	//Title
	local Title is gui:addLabel("CLS Parameters").
	set Title:style:align to "center".
	set Title:style:fontsize to 20.
	
	//Apoapsis
	local line1 is gui:ADDHLAYOUT().
	local tApoLabel1 is line1:addLabel("Desired Apoapsis").
	local tApoButton1 is line1:addbutton("Custom").
	local tApoButton2 is line1:addbutton("Highest").
	set tApoButton1:toggle to true.
	set tApoButton2:toggle to true.
	set tApoButton1:exclusive to true.
	set tApoButton2:exclusive to true.
	set tApoButton1:style:width to 55.
	set tApoButton2:style:width to 55.
	set tApoButton1:pressed to true.
	
	//Hidden Apoapsis Input
	local lineh1 is gui:ADDHLAYOUT().
	local tApoLabel2 is lineh1:addLabel("Apoapsis Input (km)").
	local tApoInput is lineh1:addtextfield("250").
	set tApoInput:style:width to 40.
	lineh1:hide().
	
	//Inclination
	local line2 is gui:ADDHLAYOUT().
	local tIncLabel is line2:addLabel("Desired Inclination (°)").
	local tIncInput is line2:addtextfield("0").
	set tIncInput:style:width to 50.
	
	//Launch window
	local line3 is gui:ADDHLAYOUT().
	local tWindowLabel1 is line3:addLabel("Launch Window").
	local tWindowButton1 is line3:addbutton("Time").
	local tWindowButton2 is line3:addbutton("tMinus").
	local tWindowButton3 is line3:addbutton("Contract").
	local tWindowButton4 is line3:addbutton("Target").
	set tWindowButton2:pressed to true.
	set tWindowButton1:toggle to true.
	set tWindowButton2:toggle to true.
	set tWindowButton3:toggle to true.
	set tWindowButton4:toggle to true.
	set tWindowButton1:exclusive to true.
	set tWindowButton2:exclusive to true.
	set tWindowButton3:exclusive to true.
	set tWindowButton4:exclusive to true.
	set tWindowButton1:style:width to 40.	
	set tWindowButton2:style:width to 50.	
	set tWindowButton4:style:width to 50.	
	set tWindowButton3:style:width to 60.	
	
	//Launch Window Input
	local line4 is gui:ADDHLAYOUT().
	local tWindowLabel2 is line4:addLabel("Time until Launch").
	local tWindowInput1 is line4:addtextfield("0").
	local tWindowLabel3 is line4:addLabel("Mins").
	set tWindowLabel3:style:width to 35.
	set tWindowInput1:style:width to 40.
	local tWindowInput2 is line4:addtextfield("23").
	local tWindowLabel4 is line4:addLabel("Secs").
	set tWindowLabel4:style:width to 35.
	set tWindowInput2:style:width to 35.
	
	//Launch Window Input
	local lineh2 is gui:ADDHLAYOUT().
	local tWindowLabel3 is lineh2:addLabel("Launch Time").
	local tWindowInput2a is lineh2:addtextfield("00").
	local tWindowInputSepa is lineh2:addLabel(":").
	local tWindowInput2b is lineh2:addtextfield("00").
	local tWindowInputSepb is lineh2:addLabel(":").
	local tWindowInput2c is lineh2:addtextfield("00").
	set tWindowInput2a:style:width to 31.
	set tWindowInputSepa:style:width to 4.
	set tWindowInput2b:style:width to 31.
	set tWindowInputSepb:style:width to 4.
	set tWindowInput2c:style:width to 31.
	lineh2:hide().
	
	//Launch Window Input
	local lineh6 is gui:ADDHLAYOUT().
	local tWindowLabel4 is lineh6:addLabel("Longitude of Ascending Node (°)").
	local tWindowInput3a is lineh6:addtextfield("").
	set tWindowInput3a:style:width to 50.
	lineh6:hide().
	
	//Max Stages
	local line5 is gui:ADDHLAYOUT().
	local mStageLabel1 is line5:addLabel("Vehicle Stages").
	local mStage1Button is line5:addbutton("1").
	local mStage2Button is line5:addbutton("2").
	local mStage3Button is line5:addbutton("3").
	local mStage4Button is line5:addbutton("4").
	local mStageMButton is line5:addbutton("More").
	set mStage1Button:toggle to true.
	set mStage2Button:toggle to true.
	set mStage3Button:toggle to true.
	set mStage4Button:toggle to true.
	set mStageMButton:toggle to true.
	set mStage1Button:exclusive to true.
	set mStage2Button:exclusive to true.
	set mStage3Button:exclusive to true.
	set mStage4Button:exclusive to true.
	set mStageMButton:exclusive to true.
	set mStage2Button:pressed to true.
	
	//Hidden Max Stages Input
	local lineh3 is gui:ADDHLAYOUT().
	local mStageLabel2 is lineh3:addLabel("Stages Input").
	local mStageInput is lineh3:addtextfield("5").
	set mStageInput:style:width to 40.
	lineh3:hide().
	
	//Data Logging
	local line6 is gui:ADDHLAYOUT().
	local dLoggingLAbel is line6:addLabel("Data Logging").
	local dLoggingInput1 is line6:addradiobutton("Yes",false).
	local dLoggingInput2 is line6:addradiobutton("No",true).
	
	//Confirm
	local confirm is gui:addbutton("Confirm Settings").
	set confirm:onclick to { set userInput to true.}.
	
	//Error Readout
	local lineh4 is gui:addvlayout().
	local Error1 is lineh4:addLabel("Error Detected").
	local Error2 is lineh4:addLabel("-").
	set Error1:Style:textcolor to red.
	set Error2:Style:textcolor to red.
	lineh4:hide().
	
	//Warning Readout
	local lineh5 is gui:addvlayout().
	local warn1 is lineh5:addLabel("Warning").
	local warn2 is lineh5:addLabel("-").
	local warn3 is lineh5:addLabel("Change the parameters or press 'Confirm Settings' to proceed").
	set warn1:Style:textcolor to yellow.
	set warn2:Style:textcolor to yellow.
	set warn3:Style:textcolor to yellow.
	lineh5:hide().
	
	gui:show().
	
	//Loop
	until confirmed {
		until userInput {				
			//Apoapsis
			if tApoButton1:pressed {
				lineh1:show().
				if tApoInput:text:length > 0 {
					global tApo is tApoInput:text:tonumber()*1000.
					global tPeri is tApoInput:text:tonumber()*1000.
				}
			} else {
				lineh1:hide().
				global tApo is maxApoapsis.
				global tPeri is maxApoapsis.
			}
			
			//Inclination
			if tIncInput:text:length > 0 {
				if tIncInput:text:startswith("-") {
					if tIncInput:text:length > 1 {
						local minus is tIncInput:text:split("-")[1].
						global tInc is 0 - minus:tonumber().
					}
				} else {
					global tInc is tIncInput:text:tonumber().
				}
			}
			if tInc < 0 or tInc > 0 and tWindowButton3:pressed {
				lineh6:show().
			} else {
				lineh6:hide().
			}				
			
			//Launch Window
			if tWindowButton1:pressed { 
				line2:show().
				line4:hide().
				lineh6:hide().
				lineh2:show().
				if tWindowInput2a:text:length > 0 and tWindowInput2b:text:length > 0 and tWindowInput2c:text:length > 0 {
					global tWindow is tWindowInput2a:text + ":" + tWindowInput2b:text + ":" + tWindowInput2c:text.
				}
			} else if tWindowButton2:pressed {
				line2:show().
				line4:show().
				lineh6:hide().
				lineh2:hide().
				if tWindowInput1:text:length > 0 {
					set tMin to tWindowInput1:text:tonumber()*60.
				}
				if tWindowInput2:text:length > 0 {
					set tSec to tWindowInput2:text:tonumber().
				}
				global tWindow is tMin + tSec.
			} else if tWindowButton3:pressed {
				line2:show().
				lineh2:hide().
				line4:hide().
				if tWindowInput3a:text:length > 0 {
					global tWindow is launchWindowContract(tInc,tWindowInput3a:text:tonumber())-(time:seconds+30).
				} else {
					global tWindow is 23.
				}
			} else if tWindowButton4:pressed {
				lineh2:hide().
				line2:hide().
				lineh6:hide().
				line4:hide().
				if hastarget = true {
					global tWindow is launchWindowRendezvous(target).
				}
			}
			
			//Stages
			if mStageMButton:pressed {
				lineh3:show().
				if mStageInput:text:length > 0 {
					global tMStages is mStageInput:text:tonumber().
				}
			} else {
				lineh3:hide().
			}
			if mStage1Button:pressed {
				global tMStages is 1.
			} else if mStage2Button:pressed {
				global tMStages is 2.
			} else if mStage3Button:pressed {
				global tMStages is 3.
			} else if mStage4Button:pressed {
				global tMStages is 4.
			} 
			
			//Data Logging
			if dLoggingInput1:pressed {
				global tDataLog is true.
			} else {
				global tDataLog is false.
			}
			wait 0.001.
		}
		//Warnings
		//Apoapsis Warning
		if tApoButton1:pressed {
			if tApo <= body:atm:height*1.43 {
				set warning to true.
				set warn2:text to "Target apoapsis is below recommended altitude. Results may vary.".
			} 
		} 

		//Apoapsisi & Periapsis switch
		if tperi > tApo {
			local temp is tApo.
			set tApo to tPeri.
			set tPeri to temp.
		}

		//Error Checking		
		//Periapsis 
		if tPeri < body:atm:height {
			set inputError to true.
			set Error2:text to "Target periapsis is below the atmosphere".
		} else if tPeri > maxApoapsis {
			set inputError to true.
			set Error2:text to "Target periapsis is above the maximum rating for CLS".
		}
			
		//Apoapsis 
		if tApo < body:atm:height {
			set inputError to true.
			set Error2:text to "Target apoapsis is below the atmosphere".
		} else if tApo > maxApoapsis {
			set inputError to true.
			set Error2:text to "Target apoapsis is above the maximum rating for CLS".
		}
			
		//Inclination
		if ABS(tInc) < Floor(ABS(launchLocation:lat)) or ABS(tInc) > 181 - Ceiling(ABS(launchLocation:lat)) {
			set inputError to true.
			set Error2:text to "Target Inclination impossible to achieve".
		}
		//Launch Window
		if tWindow < 23 {
			set inputError to true.
			set Error2:text to "Must have a tMinus of 23 or more".
		}
		if tWindowInput2a:text:tonumber() < 0 or tWindowInput2b:text:tonumber() < 0 or tWindowInput2c:text:tonumber() < 0 {
			set inputError to true.
			set Error2:text to "Time input requires positive numbers".
		}
		if tWindowInput2a:text:tonumber() > 23 or tWindowInput2a:text:tonumber() > 59 or tWindowInput2a:text:tonumber() > 59 {
			set inputError to true.
			set Error2:text to "Incorrect time detected".
		}
		if tInc < 0 or tInc > 0 and tWindowButton3:pressed {
			if tWindowInput3a:text:tonumber() < 0 or tWindowInput3a:text:tonumber() > 360 {
				set inputError to true.
				set Error2:text to "Longitude of Ascending Node must be between 0° and 360°".
			}
		}
		if tWindowButton4:pressed {
			if hastarget = false {
				set inputError to true.
				set Error2:text to "Please select a target vessel".
			}
		}
		if tMStages < 1 {
			set inputError to true.
			set Error2:text to "Must have at least 1 stage".
		}
		
		//Loop or Finalise
		if inputError = true {
			lineh4:show().
			set userInput to false.
			set inputError to false.
		} else if warning = true and warningCount < 1 {
			lineh4:hide().
			lineh5:show().
			set warningCount to warningCount+1.
			set userInput to false.
			set warning to false.
		} else {
			lineh4:hide().
			set confirmed to true.
			
			//Final data collection of inoutted values
			output:add(tApo).       //[0] Target Apoapsis
			output:add(tPeri).		//[1] Target Periapsis
			output:add(tInc).  	 	//[2] Target Inclination
			output:add(tWindow).    //[3] Launch Window
			output:add(tMStages).   //[4] Max Stages
			output:add(tDataLog).   //[5] Data Logging
			
			gui:hide().
			return output.
		}
		wait 0.001.
	}
}	