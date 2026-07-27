-- Transport + mode control for whichever supported player (Music or Spotify) is
-- active. Called by the widget via the /run/ endpoint with one argument:
--   playpause (default) | next | previous | shuffle | repeat
-- shuffle toggles; repeat cycles (Music: off -> all -> one -> off; Spotify: on/off,
-- since it has no "repeat one"). Shuffle/repeat need per-app terms, so each app is
-- handled in its own tell block.
on run argv
	set cmd to "playpause"
	if (count of argv) > 0 then set cmd to item 1 of argv
	set apps to {"Music", "Spotify"}
	repeat with anApp in apps
		tell application "System Events" to set isRunning to (name of processes) contains anApp
		if isRunning then
			if (anApp as string) is "Music" then
				tell application "Music"
					if (player state is playing) or (player state is paused) then
						if cmd is "next" then
							next track
						else if cmd is "previous" then
							previous track
						else if cmd is "shuffle" then
							set shuffle enabled to not (shuffle enabled)
						else if cmd is "repeat" then
							if (song repeat) is off then
								set song repeat to all
							else if (song repeat) is all then
								set song repeat to one
							else
								set song repeat to off
							end if
						else
							playpause
						end if
						return
					end if
				end tell
			else
				tell application "Spotify"
					if (player state is playing) or (player state is paused) then
						if cmd is "next" then
							next track
						else if cmd is "previous" then
							previous track
						else if cmd is "shuffle" then
							set shuffling to not shuffling
						else if cmd is "repeat" then
							set repeating to not repeating
						else
							playpause
						end if
						return
					end if
				end tell
			end if
		end if
	end repeat
end run
