/datum/hud/storage
	var/obj/screen/hud
		boxes
		close
	var/obj/item/storage/master
	var/list/obj_locs = null // hi, haine here, I'm gunna crap up this efficient code with REGEX BULLSHIT YEAHH!!

	New(master)
		src.master = master
		src.boxes = create_screen("boxes", "Storage", 'icons/mob/screen1.dmi', "block", ui_storage_area)
		src.close = create_screen("close", "Close", 'icons/mob/screen1.dmi', "x", ui_storage_close, HUD_LAYER+1)
		update()

	disposing()
		src.master = null
		src.boxes.dispose()
		src.close.dispose()
		src.obj_locs = null
		..()

	clear_master()
		master = null
		..()

	clicked(id, mob/user, params)
		switch (id)
			if ("boxes")
				if (params && islist(src.obj_locs))
					var/list/prams = params
					if (!islist(prams))
						prams = params2list(prams)
					if (islist(prams))
						var/clicked_loc = prams["screen-loc"] // should be in the format 1:16,1:16 (tile x : pixel offset x, tile y : pixel offset y)
						//DEBUG_MESSAGE(clicked_loc)
						//var/regex/loc_regex = regex("(\\d*):\[^,]*,(\\d*):\[^\n]*")
						//clicked_loc = loc_regex.Replace(clicked_loc, "$1,$2")
						//DEBUG_MESSAGE(clicked_loc)

						//MBC : I DONT KNOW REGEX BUT THE ABOVE IS NOT WORKING LETS DO THIS INSTEAD


						var/firstcolon = findtext(clicked_loc,":")
						var/comma = findtext(clicked_loc,",")
						var/secondcolon = findtext(clicked_loc,":",comma)
						if (firstcolon == secondcolon)
							if (firstcolon > comma)
								firstcolon = 0
							else
								secondcolon = 0

						var/x = copytext(clicked_loc,1,firstcolon ? firstcolon : comma)
						var/px = firstcolon ? copytext(clicked_loc,firstcolon+1,comma) : 0
						var/y = copytext(clicked_loc,comma+1,secondcolon ? secondcolon : 0)
						var/py = secondcolon ? copytext(clicked_loc,secondcolon+1) : 0

						if (user.client && user.client.byond_version == 512 && user.client.byond_build == 1469) //sWAP EM BECAUSE OF BAD BYOND BUG
							var/temp = y
							y = px
							px = temp

						//ddumb hack for offset storage
						var/turfd = (isturf(master.loc) && !istype(master, /obj/item/storage/bible))

						var/pixel_y_adjust = 0
						if (usr && usr.client && usr.client.tg_layout && !turfd)
							pixel_y_adjust = 1

						if (pixel_y_adjust && text2num(py) > 16)
							y = text2num(y) + 1
							py = text2num(py) - 16
						//end dumb hack

						clicked_loc = "[x],[y]"


						var/obj/item/I = src.obj_locs[clicked_loc]
						if (I)
							//DEBUG_MESSAGE("clicking [I] with params [list2params(params)]")
							user.click(I, params)
						else if (user.equipped())
							//DEBUG_MESSAGE("clicking [src.master] with [user.equipped()] with params [list2params(params)]")
							user.click(src.master, params)

			if ("close")
				user.detach_hud(src)
				user.s_active = null

	proc/update()
		var x = 1
		var y = 1 + master.slots
		var sx = 1
		var sy = master.slots + 1
		var/turfd = 0

		if (isturf(master.loc) && !istype(master, /obj/item/storage/bible)) // goddamn BIBLES (prevents conflicting positions within different bibles)
			x = 7
			y = 8
			sx = (master.slots + 1) / 2
			sy = 2

			turfd = 1

		if (istype(usr,/mob/living/carbon/human))
			if (usr.client && usr.client.tg_layout) //MBC TG OVERRIDE IM SORTY
				x = 1 + master.slots
				y = 3
				sx = master.slots + 1
				sy = 1

				if (turfd) // goddamn BIBLES (prevents conflicting positions within different bibles)
					x = 7
					y = 8
					sx = (master.slots + 1) / 2
					sy = 2

		if (!boxes)
			return
		if (ishuman(usr))
			var/mob/living/carbon/human/player = usr
			var/icon/hud_style = hud_style_selection[get_hud_style(player)]
			if (isicon(hud_style) && boxes.icon != hud_style)
				boxes.icon = hud_style

		var/pixel_y_adjust = 0
		if (usr && usr.client && usr.client.tg_layout && !turfd)
			pixel_y_adjust = -16

		boxes.screen_loc = "[x],[y]:[pixel_y_adjust] to [x+sx-1],[y-sy+1]:[pixel_y_adjust]"
		if (!close)
			src.close = create_screen("close", "Close", 'icons/mob/screen1.dmi', "x", ui_storage_close, HUD_LAYER+1)
		close.screen_loc = "[x+sx-1]:[pixel_y_adjust],[y-sy+1]:[pixel_y_adjust]"

		if (!turfd && istype(usr,/mob/living/carbon/human))
			if (usr && usr.client && usr.client.tg_layout) //MBC TG OVERRIDE IM SORTY
				boxes.screen_loc = "[x-1],[y]:[pixel_y_adjust] to [x+sx-2],[y-sy+1]:[pixel_y_adjust]"
				close.screen_loc = "[x-1],[y-sy+1]:[pixel_y_adjust]"

		src.obj_locs = list()
		var/i = 0
		for (var/obj/item/I in master.get_contents())
			if (!(I in src.objects)) // ugh
				add_object(I, HUD_LAYER+1)
			var/obj_loc = "[x+(i%sx)],[y-round(i/sx)]" //no pixel coords cause that makes click detection harder above
			var/final_loc = "[x+(i%sx)],[y-round(i/sx)]:[pixel_y_adjust]"
			I.screen_loc = final_loc
			src.obj_locs[obj_loc] = I
			i++
		master.update_icon()

	proc/add_item(obj/item/I)
		update()

	proc/remove_item(obj/item/I)
		remove_object(I)
		update()
