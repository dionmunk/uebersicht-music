global artistName, songName, albumName, songYear, songDuration, currentPosition, musicapp, songMetaFile, mypath, currentCoverURL, isLoved, playerState, shuffleState, repeatState
global cacheKeys, cacheVals, dirtyKeys
property enableLogging : false --- options: true | false

set metaToGrab to {"artistName", "songName", "albumName", "songYear", "songDuration", "currentPosition", "coverURL", "songChanged", "isLoved", "darkMode", "playerState", "shuffle", "repeat"}
set allKeys to metaToGrab & {"oldFilename"}

try
	set mypath to POSIX path of (path to me)
	set AppleScript's text item delimiters to "/"
	set mypath to (mypath's text items 1 thru -2 as string) & "/"
	set AppleScript's text item delimiters to ""
on error e
	logEvent(e)
	return
end try

set songMetaFile to (mypath & "songMeta.plist" as string)
ensurePlistFile()

set cacheKeys to {}
set cacheVals to {}
set dirtyKeys to {}
loadCache(allKeys)

if isMusicPlaying() is true then
	getSongMeta()
	cacheSet("currentPosition", currentPosition)
	cacheSet("darkMode", checkDarkMode() as string)
	cacheSet("playerState", playerState)
	getPlaybackModes()
	cacheSet("shuffle", shuffleState)
	cacheSet("repeat", repeatState)

	if didSongChange() is true then
		if didCoverChange() is true then
			set savedCoverURL to cacheGet("coverURL")
			set currentCoverURL to grabCover()
			if currentCoverURL is not savedCoverURL then cacheSet("coverURL", currentCoverURL)
		end if
		cacheSet("artistName", artistName)
		cacheSet("songName", songName)
		cacheSet("albumName", albumName)
		cacheSet("songYear", songYear as string)
		cacheSet("songDuration", songDuration as string)
		cacheSet("isLoved", isLoved)
		cacheSet("songChanged", "true")
	else
		cacheSet("songChanged", "false")
		cacheSet("isLoved", isLoved)
	end if
	flushCache()
else
	return
end if

return spitOutput(metaToGrab)

------------------------------------------------
---------------SUBROUTINES GALORE---------------
------------------------------------------------

on isMusicPlaying()
	set apps to {"Music", "Spotify"}
	set answer to false
	repeat with anApp in apps
		tell application "System Events" to set isRunning to (name of processes) contains anApp
		if isRunning is true then
			try
				using terms from application "Music"
					tell application anApp
						if (player state is playing) or (player state is paused) then
							set musicapp to (anApp as string)
							set answer to true
							if player state is paused then
								set playerState to "paused"
							else
								set playerState to "playing"
							end if
						end if
					end tell
				end using terms from
			on error e
				my logEvent(e)
			end try
		end if
	end repeat
	return answer
end isMusicPlaying

on getSongMeta()
	try
		set musicAppReference to a reference to application musicapp
		using terms from application "Music"
			try
				tell musicAppReference
					-- Common properties both players expose. "year" is fetched separately
					-- below because Spotify's current track has no such property (asking for
					-- it throws and would abort the whole grab).
					set {artistName, songName, albumName, songDuration} to {artist, name, album, duration} of current track
					if musicapp is "Music" then
						set songYear to year of current track
						set isLoved to favorited of current track as string
					else if musicapp is "Spotify" then
						-- Spotify exposes no release year, so hide the year (the widget skips
						-- "NA"). It also removed the "starred" API (no public way to read
						-- "Liked Songs"), so isLoved is NA and the widget hides the indicator
						-- instead of falsely showing "not favorited". Duration is in ms, so
						-- comma_delimit + formatNum (below) trims it down to whole seconds.
						set songYear to "NA"
						set isLoved to "NA"
						set songDuration to my comma_delimit(songDuration)
					end if
					set currentPosition to my formatNum(player position as string)
					set songDuration to my formatNum(songDuration as string)
				end tell
			on error e
				my logEvent(e)
			end try
		end using terms from
	on error e
		my logEvent(e)
	end try
	return songDuration
end getSongMeta

on getPlaybackModes()
	-- shuffle -> "true"/"false"; repeat -> "off"/"one"/"all". Spotify has no
	-- "repeat one", so its repeating=true maps to "all".
	set shuffleState to "false"
	set repeatState to "off"
	try
		if musicapp is "Music" then
			tell application "Music"
				set shuffleState to (shuffle enabled) as string
				set rp to song repeat
				if rp is one then
					set repeatState to "one"
				else if rp is all then
					set repeatState to "all"
				else
					set repeatState to "off"
				end if
			end tell
		else if musicapp is "Spotify" then
			tell application "Spotify"
				set shuffleState to (shuffling) as string
				if (repeating) then
					set repeatState to "all"
				else
					set repeatState to "off"
				end if
			end tell
		end if
	on error e
		my logEvent(e)
	end try
end getPlaybackModes

on didSongChange()
	set answer to false
	try
		set currentSongMeta to artistName & songName
		set savedSongMeta to (my cacheGet("artistName") & my cacheGet("songName") as string)
		if currentSongMeta is not savedSongMeta then set answer to true
	on error e
		my logEvent(e)
	end try
	my logEvent("didSongChange: " & answer)
	return answer
end didSongChange

on didCoverChange()
	set answer to false
	try
		set currentSongMeta to artistName & albumName
		set savedSongMeta to (my cacheGet("artistName") & my cacheGet("albumName") as string)
		if currentSongMeta is not savedSongMeta then set answer to true
		if my cacheGet("coverURL") is "NA" then set answer to true
	on error e
		my logEvent(e)
	end try
	my logEvent("didCoverChange: " & answer)
	return answer
end didCoverChange

on grabCover()
	-- always drop the previous cover before generating a new one
	pruneCovers()
	my cacheSet("oldFilename", "")
	set currentCoverURL to "NA"
	try
		if musicapp is "Music" then
			set hasArtwork to false
			tell application "Music"
				try
					if (count of artworks of current track) > 0 then set hasArtwork to true
				end try
			end tell
			if hasArtwork then my getLocalMusicArt()
		else if musicapp is "Spotify" then
			my getSpotifyArt()
		end if
	on error e
		my logEvent(e)
		set currentCoverURL to "NA"
	end try
	my logEvent("currentCoverURL: " & currentCoverURL)
	return currentCoverURL
end grabCover

on getLocalMusicArt()
	tell application "Music" to tell artwork 1 of current track
		set srcBytes to raw data
		if format is «class PNG » then
			set ext to ".png"
		else
			set ext to ".jpg"
		end if
	end tell

	-- unique filename so Übersicht's browser doesn't serve a stale cached image
	set epochSeconds to (do shell script "date +%s")
	set fileName to (mypath as POSIX file) & epochSeconds & ext as string
	set outFile to open for access file fileName with write permission
	set eof outFile to 0
	write srcBytes to outFile
	close access outFile
	set posixPath to POSIX path of fileName
	my cacheSet("oldFilename", posixPath)
	set currentCoverURL to my getPathItem(posixPath)
end getLocalMusicArt

on getSpotifyArt()
	try
		tell application "Spotify" to set currentCoverURL to artwork url of current track
	on error e
		my logEvent(e)
		set currentCoverURL to "NA"
	end try
end getSpotifyArt

on pruneCovers()
	set oldF to my cacheGet("oldFilename")
	if oldF is "" or oldF is "NA" then return
	try
		do shell script "rm " & quoted form of oldF
	on error e
		my logEvent(e)
	end try
end pruneCovers

on checkDarkMode()
	try
		tell application "System Events" to tell appearance preferences to return dark mode
	on error
		return false
	end try
end checkDarkMode

on getPathItem(aPath)
	set AppleScript's text item delimiters to "/"
	set countItems to count text items of aPath
	set start to countItems - 2
	set outputPath to "/" & text items start thru -1 of aPath as string
	set AppleScript's text item delimiters to ""
	return outputPath
end getPathItem

on ensurePlistFile()
	if my checkFile(songMetaFile) is false then
		tell application "System Events"
			set parent_dictionary to make new property list item with properties {kind:record}
			make new property list file with properties {contents:parent_dictionary, name:songMetaFile}
		end tell
	end if
end ensurePlistFile

on loadCache(keyNames)
	-- one batched read pulls every key we care about into in-memory parallel lists
	tell application "System Events" to tell property list file songMetaFile to tell contents
		repeat with keyName in keyNames
			set kStr to keyName as string
			try
				set kVal to value of property list item kStr
			on error
				set kVal to "NA"
			end try
			set end of cacheKeys to kStr
			set end of cacheVals to (kVal as string)
		end repeat
	end tell
end loadCache

on cacheGet(k)
	repeat with i from 1 to count of cacheKeys
		if (item i of cacheKeys) is k then return item i of cacheVals
	end repeat
	return "NA"
end cacheGet

on cacheSet(k, v)
	set vStr to v as string
	repeat with i from 1 to count of cacheKeys
		if (item i of cacheKeys) is k then
			if (item i of cacheVals) is not vStr then
				set item i of cacheVals to vStr
				if dirtyKeys does not contain k then set end of dirtyKeys to k
			end if
			return
		end if
	end repeat
	set end of cacheKeys to k
	set end of cacheVals to vStr
	if dirtyKeys does not contain k then set end of dirtyKeys to k
end cacheSet

on flushCache()
	if (count of dirtyKeys) is 0 then return
	set pairs to {}
	repeat with k in dirtyKeys
		set kStr to k as string
		set end of pairs to kStr & "##" & my cacheGet(kStr)
	end repeat
	my writeSongMeta(pairs)
end flushCache

on writeSongMeta(keys)
	tell application "System Events"
		try
			repeat with aKey in keys
				set AppleScript's text item delimiters to "##"
				set keyName to text item 1 of aKey
				set keyValue to text item 2 of aKey
				set AppleScript's text item delimiters to ""
				make new property list item at end of property list items of contents of property list file songMetaFile with properties {kind:string, name:keyName, value:keyValue}
			end repeat
		on error e
			my logEvent(e)
		end try
	end tell
end writeSongMeta

on spitOutput(metaToGrab)
	set valuesList to {}
	repeat with metaPiece in metaToGrab
		set valuesList to valuesList & my cacheGet(metaPiece as string) & " @ "
	end repeat
	set AppleScript's text item delimiters to ""
	set output to (items 1 thru -2 of valuesList) as string
	set AppleScript's text item delimiters to ""
	return output
end spitOutput

on formatNum(aNumber)
	set delimiters to {",", "."}
	repeat with aDelimiter in delimiters
		if aNumber contains aDelimiter then
			set AppleScript's text item delimiters to aDelimiter
			set outValue to text item 1 of aNumber
			set AppleScript's text item delimiters to ""
			return outValue
		end if
	end repeat
	if aNumber does not contain delimiters then return aNumber
end formatNum

on comma_delimit(this_number)
	set this_number to this_number as string
	if this_number contains "E" then set this_number to number_to_string(this_number)
	set the num_length to the length of this_number
	set the this_number to (the reverse of every character of this_number) as string
	set the new_num to ""
	repeat with i from 1 to the num_length
		if i is the num_length or (i mod 3) is not 0 then
			set the new_num to (character i of this_number & the new_num) as string
		else
			set the new_num to ("." & character i of this_number & the new_num) as string
		end if
	end repeat
	return the new_num
end comma_delimit

on number_to_string(this_number)
	set this_number to this_number as string
	if this_number contains "E+" then
		set x to the offset of "." in this_number
		set y to the offset of "+" in this_number
		set z to the offset of "E" in this_number
		set the decimal_adjust to characters (y - (length of this_number)) thru -1 of this_number as string as number
		if x is not 0 then
			set the first_part to characters 1 thru (x - 1) of this_number as string
		else
			set the first_part to ""
		end if
		set the second_part to characters (x + 1) thru (z - 1) of this_number as string
		set the converted_number to the first_part
		repeat with i from 1 to the decimal_adjust
			try
				set the converted_number to the converted_number & character i of the second_part
			on error
				set the converted_number to the converted_number & "0"
			end try
		end repeat
		return the converted_number
	else
		return this_number
	end if
end number_to_string

on checkFile(myfile)
	try
		POSIX file myfile as alias
		return true
	on error
		return false
	end try
end checkFile

on logEvent(e)
	if enableLogging is true then
		set e to e as string
		do shell script "echo " & quoted form of (((current date) as string) & " " & e) & " >> ~/Library/Logs/CurrentTrack.log"
	end if
end logEvent
