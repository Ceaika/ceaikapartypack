Resource/UI/LoadingProgress.res
{
	LoadingProgress
	{
		ControlName				Frame
		wide					f0
		tall					f0
		visible					1
		enabled					1
		tabPosition				0
	}

	GradientOverlay
	{
		ControlName				ImagePanel
		wide					%100
		tall					%100
		image					"loadscreens/gradient_overlay"
		scaleImage				1
		visible					0

		pin_to_sibling			LoadingGameMode
		pin_corner_to_sibling	TOP_LEFT
		pin_to_sibling_corner	BOTTOM_LEFT
	}

	LoadingGameMode
	{
		ControlName             Label
		xpos                    r1690
		ypos                    504
		wide                    1600
		tall                    78
		labelText               ""
		textAlignment           east
		font                    PartyLoadingMode
		fgcolor_override        "255 255 255 255"
		allcaps                 0
		visible                 1
		zpos                    70
	}

	TitleSeparator
	{
		ControlName				ImagePanel
		xpos                    20
		wide                    2
		tall                    74
		image					"loadscreens/title_separator"
		scaleImage				1
		visible					0

		pin_to_sibling			LoadingGameMode
		pin_corner_to_sibling	LEFT
		pin_to_sibling_corner	RIGHT
	}

	LoadingMapName
	{
		ControlName             Label
		xpos                    r1690
		ypos                    391
		wide                    1600
		tall                    108
		labelText               ""
		textAlignment           east
		font                    PartyLoadingMap
		fgcolor_override        "255 255 255 255"
		allcaps                 1
		visible                 1
		zpos                    70
	}

	LoadingTip
	{
		ControlName             Label
		xpos                    r1390
		ypos                    936
		wide                    1300
		tall                    85
		labelText               ""
		textAlignment           south-east
		wrap                    1
		font                    PartyLoadingTip
		fgcolor_override        "255 255 255 255"
		visible                 1
		zpos                    70
	}

	WorkingAnim
	{
		ControlName             ImagePanel
		xpos                    70
		ypos                    845
		wide                    210
		tall                    210
		visible                 0
		enabled                 1
		tabPosition             0
		scaleImage              1
		image                   "vgui/spinner"
		frame                   0
		zpos                    80
	}

	
	LoadingLabelInfo
	{
		ControlName				Label
		xpos					r400
		ypos					r85
		tall 50
		wide 300
		labelText				""
		textAlignment				east
		font					Default_21
		fgcolor_override 		"255 255 255 255"
		visible					1
	}


	//LoadingTeamLogo
	//{
	//	ControlName				ImagePanel
	//	ypos					130
	//	wide					108
	//	tall					108
	//	image					"ui/temp"
	//	scaleImage				1
	//	visible					0
    //
	//	pin_to_sibling			LoadingGameMode
	//	pin_corner_to_sibling	TOP_LEFT
	//	pin_to_sibling_corner	BOTTOM_LEFT
	//}

	//LoadingMapDesc
	//{
	//	ControlName				Label
	//	xpos					0
	//	ypos					27
	//	wide					1385 [$WIDESCREEN_16_9]
	//	wide					1203 [!$WIDESCREEN_16_9]
	//	tall 					108
	//	labelText				""
	//	textalign				"north-west"
	//	font					LoadScreenMapDesc
	//	wrap 					1
	//	fgcolor_override 		"200 200 200 255"
	//	visible					0
    //
	//	pin_to_sibling			LoadingGameMode
	//	pin_corner_to_sibling	TOP_LEFT
	//	pin_to_sibling_corner	BOTTOM_LEFT
	//}

	LoadingProgressBar
	{
		ControlName             ContinuousProgressBar
		xpos                    0
		ypos                    0
		wide                    0
		tall                    0
		visible                 0
		enabled                 0
		bgcolor_override        "0 0 0 0"
		fgcolor_override        "0 0 0 0"
	}

	GameModeInfoRui
	{
		ControlName				RuiPanel
		classname				"RuiLoadingThing"
		xpos					110
		wide					1080
		tall					1080
		visible					1
		rui 					"ui/loadscreen_game_mode_info.rpak"
		drawColor				"255 0 255 255"
	}

	DetentText
	{
		ControlName				RuiPanel
		classname				"RuiDetentText"
		wide					f0
		tall					f0
		visible					0
		rui 					"ui/loadscreen_detent.rpak"
		drawColor				"255 0 255 255"
	}

	SPLog
	{
		ControlName				RuiPanel
		classname				"RuiSPLog"
		wide					f0
		tall					f0
		visible					0
		rui 					"ui/loadscreen_sp_log.rpak"
		drawColor				"255 0 255 255"
	}

	PartyCard
	{
		ControlName             ImagePanel
		xpos                    0
		ypos                    0
		wide                    f0
		tall                    f0
		fillColor               "253 75 1 255"
		visible                 1
		zpos                    50
	}

	PartyTitle
	{
		ControlName             ImagePanel
		xpos                    86
		ypos                    30
		wide                    532
		tall                    231
		image                   "vgui/ceaika/loadscreen_title"
		scaleImage              1
		visible                 1
		zpos                    52
	}
}
