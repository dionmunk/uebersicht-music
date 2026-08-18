options =
  # --- Location -------------------------------------------------------------
  # Enable or disable the widget.
  widgetEnabled : true                 # true | false

  # Where the widget sits on your screen.
  verticalPosition : "bottom"          # top | bottom | center
  horizontalPosition : "left"          # left | right | center

  # --- Layout ---------------------------------------------------------------
  # Layout orientation.
  #   "horizontal": one row, album art + track info on the left, a divider,
  #                 then the transport controls on the right.
  #   "vertical":   one column, album art (full width), then track info, then
  #                 the controls, then the progress bar.
  #   "square":     a square widget, the album art is a full-bleed background
  #                 (opaque at the top, fading out toward the bottom) over the
  #                 panel, with the content snapped to the bottom.
  layout : "square"                    # horizontal | vertical | square

  # Show the transport controls (previous / play-pause / next, shuffle, repeat)
  # and the divider. When false, the widget collapses to a single column and the
  # album art doubles as a play/pause button.
  controls : true                      # true | false

  # --- Content --------------------------------------------------------------
  # How the track text (artist, song, album/year) is aligned in its column.
  contentAlign : "center"              # left | center | right

  # Show the playing app's icon (Apple Music / Spotify) in the corner of the
  # square layout. No effect in the horizontal or vertical layouts.
  showAppIcon : true                   # true | false

  # Progress bar position.
  #   "full":    full-width bar below album art + metadata (default).
  #   "compact": bar tucked inside the track-info column, beneath the album/year line.
  progressBarPosition : "full"         # full | compact

  # Show the time labels next to the progress bar at all. When false the bar
  # fills the entire row and showRemainingTime/showBothTimes are ignored.
  showTime : true                      # true | false

  # Show time as -M:SS (remaining) instead of M:SS (elapsed).
  showRemainingTime : false            # true | false

  # Show elapsed AND remaining on opposite sides of the bar (overrides the above).
  showBothTimes : true                 # true | false

command: "music.widget/lib/music.sh"
refreshFrequency: '1s'
style: """

// setup
// --------------------------------------------------
display: none
font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif
font-size: 10px
margin = 10px
position: absolute

// variables
// --------------------------------------------------
widgetWidth 300px
borderRadius 6px
infoHeight 72px
infoWidth @widgetWidth - 82

// screen positioning calculations
// --------------------------------------------------
if #{options.verticalPosition} == center
    top 50%
    transform translateY(-50%)
else
    #{options.verticalPosition} margin

if #{options.horizontalPosition} == center
    left 50%
    transform translateX(-50%)
else
    #{options.horizontalPosition} margin

// styles
// --------------------------------------------------
.container
    width: @widgetWidth
    text-align: left
    position: relative
    clear: both
    color var(--text, #fff)
    text-shadow: 0 1px 1px rgba(20, 1, 1, 0.2)
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    padding 10px
    border-radius 10px

.top-row
    height: @infoHeight
    position: relative

.bottom-row
    position: relative
    height: 12px
    margin-top: 8px
    clear: both

// Compact layout: pull the bar (and times) up into the track-info column,
// pinned to the bottom of the top-row so everything fits in the album-art's
// 72px height. Metadata margins tighten so the bar has clear space below the
// album line.
.layout-compact .bottom-row
    position: absolute
    left: 92px
    right: 12px
    top: 71px
    margin-top: 0
    height: 12px

.layout-compact .artist-name
    margin-top: 4px
    margin-bottom: 1px

.layout-compact .song-name
    margin-top: 1px
    margin-bottom: 2px

.layout-compact .bar-container
    top: 4px   // bar sits 1px above the times, which stay flush with the album-art bottom

.album-art
    width: @infoHeight
    height: @width
    border-radius @borderRadius
    background-image: url(music.widget/lib/default.png)
    background-size: cover
    float: left
    position: relative
    cursor: pointer   // click to play/pause the active player

// Show the play/pause overlay on hover (in addition to always-on when paused),
// so it reads as a button.
.album-art:hover .pause-overlay
    opacity: 1

// While hovering it's a button, not a status indicator, hold the icon steady.
.album-art:hover .pp-play
    animation: none

.pause-overlay
    position: absolute
    top: 0
    left: 0
    width: 100%
    height: 100%
    border-radius: @borderRadius
    display: flex
    align-items: center
    justify-content: center
    background: rgba(#000, .35)
    opacity: 0
    transition: opacity .25s ease
    pointer-events: none

// Action icon in the overlay: pause bars (click to pause) while playing, play
// triangle (click to resume) while paused, swapped by .is-paused below.
.pp-icon.pp-pause
    width: 18px
    height: 22px
    border-left: 6px solid #fff
    border-right: 6px solid #fff
    box-sizing: border-box

.pp-icon.pp-play
    width: 0
    height: 0
    border-left: 20px solid #fff
    border-top: 12px solid transparent
    border-bottom: 12px solid transparent
    margin-left: 5px   // optical centering (triangle points right)
    display: none

.is-paused .pp-pause
    display: none

.is-paused .pp-play
    display: block
    animation: pp-pulse 5s ease-in-out infinite

// --- Divider + transport controls -----------------------------------------
// Hidden by default (single column); shown + positioned when controls are on.
.divider
    display: none

.controls
    display: none

// Controls shown: two columns, 650px footprint (2·320 + 10 gap) → 630px content.
.container.layout-horizontal
    width: 630px

// With controls shown (either layout) the album art is just artwork, no
// overlay, not clickable. When controls are hidden it stays the play button.
.container.show-controls .album-art
    cursor: default

.container.show-controls .pause-overlay
    display: none

// The track content keeps its width on the left; the divider + controls sit
// in the right half of the top row.
.layout-horizontal .divider
    display: block
    position: absolute
    left: 315px
    top: 6px
    height: 60px
    width: 1px
    // Match the weather widget's divider: same --level-base grey + soft shadow.
    background: var(--level-base, rgba(#fff, .2))
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)

.layout-horizontal .controls
    display: flex
    align-items: center
    justify-content: center
    gap: 20px
    position: absolute
    left: 315px
    right: 0
    top: 0
    height: @infoHeight
    color: var(--text, #fff)

// --- Stacked layouts (vertical + square) ----------------------------------
// Both are a single column of centered content: track info → controls →
// progress bar. 'vertical' adds the album art as a full-width block on top;
// 'square' uses it as a faded full-bleed background instead. The controls row
// shows only when controls are enabled.
.container.layout-stacked
    width: @widgetWidth

.layout-stacked .top-row
    height: auto
    display: flex
    flex-direction: column
    gap: 18px

// Track info stacks full-width so contentAlign can center it.
.layout-stacked .track-info
    float: none
    width: 100%
    height: auto
    margin-left: 0

.layout-stacked .artist-name,
.layout-stacked .song-name,
.layout-stacked .album-name
    float: none
    width: 100%
    margin-left: 0
    margin-right: 0

// First line flush to the top of the block (the flex gap handles the spacing
// above it), last line flush to the bottom.
.layout-stacked .artist-name
    margin-top: 0

.layout-stacked .album-name
    margin-bottom: 0

// Controls sit in their own row, centered across the column (static, not the
// absolute right-half placement the horizontal layout uses).
.layout-stacked.show-controls .controls
    display: flex
    align-items: center
    justify-content: center
    gap: 20px
    position: static
    width: 100%
    height: auto
    color: var(--text, #fff)

.layout-stacked .bottom-row
    margin-top: 18px

// --- Vertical layout ------------------------------------------------------
// Album art fills the column width as a square block on top of the stack.
.layout-vertical .album-art
    float: none
    width: 100%
    height: auto
    aspect-ratio: 1 / 1

// --- Square layout --------------------------------------------------------
// A square widget: the album art becomes a full-bleed background over the
// translucent panel, masked so it's fully transparent at the top and fully
// opaque at the bottom. Content stays snapped to the bottom, above the art.
.container.layout-square
    aspect-ratio: 1 / 1
    position: relative
    display: flex
    flex-direction: column
    justify-content: flex-end   // snap the content to the bottom
    overflow: hidden            // clip the full-bleed art to the panel's rounded corners
    border-radius: 10px         // standard panel radius
    // WebKit doesn't clip backdrop-filter tightly to the radius, leaving a light
    // fringe at the corners that shows against the opaque album art. Drop the blur
    // here (the flat panel tint stays); the top is opaque art anyway.
    -webkit-backdrop-filter: none
    backdrop-filter: none

// Base .top-row is position:relative; make it static so the absolutely
// positioned album art fills the whole container, not just the top row.
.layout-square .top-row
    position: static

.layout-square .album-art
    position: absolute
    inset: 0
    width: auto
    height: auto
    float: none
    z-index: 0
    // Round the art to match the container exactly. Relying on the container's
    // overflow clip alone leaves a ~1px double-clip seam at the corners (the desktop
    // bleeding through); giving the art its own matching radius rounds it cleanly.
    border-radius: 10px
    // Fully opaque down to 35%, then fades to 15% opacity by the bottom.
    -webkit-mask-image: linear-gradient(to bottom, #000 35%, rgba(0, 0, 0, 0.15) 100%)
    mask-image: linear-gradient(to bottom, #000 35%, rgba(0, 0, 0, 0.15) 100%)

// Keep the content layered above the album-art background.
.layout-square .track-info,
.layout-square .bottom-row
    position: relative
    z-index: 1

.layout-square.show-controls .controls
    position: relative
    z-index: 1

// App badge: the icon of the app currently playing (Apple Music / Spotify).
// Shown only in the square layout, tucked into the top-right over the art.
.app-badge
    display: none

.layout-square.show-app-icon .app-badge
    display: block
    position: absolute
    top: 10px
    right: 10px
    width: 22px
    height: 22px
    background-size: contain
    background-repeat: no-repeat
    background-position: center
    cursor: pointer
    z-index: 2
    opacity: 0.5
    transition: opacity .2s ease
    // Standard widget shadow (drop-shadow since the badge is an image, matching
    // the text-shadow used across the widgets). Übersicht strips filter from any
    // rule that sets opacity unless the filter is declared here, so it stays.
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

// Full opacity on hover (re-declare the shadow so it survives, per above).
.layout-square.show-app-icon .app-badge:hover
    opacity: 1
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

.ctrl
    cursor: pointer
    position: relative
    transition: transform .15s ease

// Slight zoom on hover for a bit of tactility.
.ctrl:hover
    transform: scale(1.15)

// Transport icons are SF Symbols rendered to PNG masks (lib/render-controls.swift),
// tinted by currentColor (the controls inherit var(--text)), so they follow the theme.
.ctrl-prev, .ctrl-next, .cpp-play, .cpp-pause
    background: currentColor
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    mask-repeat: no-repeat
    mask-position: center
    mask-size: contain
    // Standard widget shadow. text-shadow can't apply to a masked shape, so use
    // drop-shadow, which shadows the icon silhouette with the same values.
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

.ctrl-prev
    width: 42px
    height: 27px
    -webkit-mask-image: url(music.widget/lib/icons/backward.fill.ink.png)
    mask-image: url(music.widget/lib/icons/backward.fill.ink.png)

.ctrl-next
    width: 42px
    height: 27px
    -webkit-mask-image: url(music.widget/lib/icons/forward.fill.ink.png)
    mask-image: url(music.widget/lib/icons/forward.fill.ink.png)

// Middle: play.fill (paused) / pause.fill (playing), swapped by .is-paused.
.ctrl-playpause
    width: 44px
    height: 44px
    display: flex
    align-items: center
    justify-content: center

.cpp-play, .cpp-pause
    width: 44px
    height: 44px

.cpp-play
    -webkit-mask-image: url(music.widget/lib/icons/play.fill.ink.png)
    mask-image: url(music.widget/lib/icons/play.fill.ink.png)
    display: none

.cpp-pause
    -webkit-mask-image: url(music.widget/lib/icons/pause.fill.ink.png)
    mask-image: url(music.widget/lib/icons/pause.fill.ink.png)
    display: block

.is-paused .cpp-play
    display: block
    animation: pp-pulse 5s ease-in-out infinite

.is-paused .cpp-pause
    display: none

// Hovering holds the play icon steady (no pulse), it reads as a button then.
.ctrl-playpause:hover .cpp-play
    animation: none

// Shuffle / repeat status indicators (read-only): masked SF Symbols, dim when off,
// full opacity when active. State (and the repeat/repeat.1 swap) set in update().
.status
    background: currentColor
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    mask-repeat: no-repeat
    mask-position: center
    mask-size: contain
    opacity: 0.3
    cursor: pointer
    transition: opacity .2s ease, transform .15s ease
    // Standard widget shadow (drop-shadow, since these are masked shapes).
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

// Übersicht appends `filter: none` to any rule that sets opacity, which would
// wipe the base .status drop-shadow. Re-declaring the shadow here keeps it (a
// rule that already sets filter is left untouched).
.status.on
    opacity: 1
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

// Hovering brightens + slightly zooms, so the indicators read as toggles.
.status:hover
    opacity: 1
    transform: scale(1.15)
    filter: drop-shadow(0 1px 1px rgba(20, 1, 1, 0.2))

.status-shuffle
    width: 24px
    height: 18px
    -webkit-mask-image: url(music.widget/lib/icons/shuffle.ink.png)
    mask-image: url(music.widget/lib/icons/shuffle.ink.png)

.status-repeat
    width: 24px
    height: 18px
    -webkit-mask-image: url(music.widget/lib/icons/repeat.ink.png)
    mask-image: url(music.widget/lib/icons/repeat.ink.png)

.track-info
    width: @infoWidth
    height: @infoHeight
    margin-left: 10px
    position: relative
    float: left

.artist-name
    font-size: 12px
    font-weight: 300
    margin-top: 7px
    margin-bottom: 5px
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    float: left
    width: 218px

.is-loved
    color: var(--primary, var(--loved, #e84341))
    font-size: 11px
    font-weight: bold
    -webkit-text-stroke: 1px currentColor   // thickens the star glyph (bolder look)
    position: relative
    top: -1px
    margin-left: 7px

.song-name
    font-size: 15px
    font-weight: 600
    margin-top: 0
    margin-bottom: 6px
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    float: left
    width: 218px

.album-name
    font-size: 12px
    font-weight: 300
    margin-top: 0
    margin-right: 5px
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    float: left
    width: 218px

.time-elapsed
    position: absolute
    top: 1px
    left: 0
    font-size: 10px
    font-weight: bold
    line-height: 1
    width: 28px
    text-align: left

.time-remaining
    position: absolute
    top: 1px
    right: 0
    font-size: 10px
    font-weight: bold
    line-height: 1
    width: 28px
    text-align: right
    display: none

.bar-container
    width: calc(100% - 30px)
    height: @borderRadius
    border-radius: @borderRadius
    background: var(--level-base, rgba(#fff, .2))
    position: absolute
    top: 4px
    left: 30px
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // base bar: matches text shadow

.mode-remaining .time-elapsed
    display: none

.mode-remaining .time-remaining
    display: block

.mode-remaining .bar-container
    left: 0

.mode-both .time-remaining
    display: block

.mode-both .bar-container
    width: calc(100% - 61px)   // 1px narrower on the right → 3px gap to time-remaining (2px on the elapsed side)

// No-time: hide both time labels and let the bar fill the row.
// Declared after the mode-* rules so it overrides them at equal specificity.
.no-time .time-elapsed,
.no-time .time-remaining
    display: none

.no-time .bar-container
    left: 0
    width: 100%

.bar
    height: @borderRadius
    border-radius: @borderRadius
    transition: width .2s ease-in-out
    box-shadow: 1px 0 3px rgba(0, 0, 0, 0.04)   // faint separation under the cap

.bar-progress
    background: var(--level-max, rgba(#fff, 1))

.marquee-text
    display: inline-block
    white-space: nowrap

// Track-text alignment, driven by the `contentAlign` option (a class on the
// container). Applies to the artist, song, and album/year lines.
.align-left .artist-name, .align-left .song-name, .align-left .album-name
    text-align: left
.align-center .artist-name, .align-center .song-name, .align-center .album-name
    text-align: center
.align-right .artist-name, .align-right .song-name, .align-right .album-name
    text-align: right

.is-marquee
    text-overflow: clip

// Scrolling (overflowing) text must always start at the left edge, whatever the
// chosen alignment. Placed after the align rules so it wins at equal specificity.
.align-left .is-marquee, .align-center .is-marquee, .align-right .is-marquee
    text-align: left

.is-marquee .marquee-text
    animation-name: marquee
    animation-duration: var(--marquee-duration, 10s)
    animation-timing-function: linear
    animation-iteration-count: infinite

.is-paused .marquee-text
    animation-play-state: paused

.is-paused .pause-overlay
    opacity: 1

@keyframes pp-pulse
    0%, 50%        // hold white ~2.5s
        opacity: 1
    75%            // ...then a slow smooth dip (~2.5s), grey only at the bottom (no hold)
        opacity: 0.4
    100%           // ...and smoothly back to white
        opacity: 1

@keyframes marquee
    0%, 12%
        transform: translateX(0)
    50%, 62%
        transform: translateX(var(--marquee-distance, 0))
    98%, 100%
        transform: translateX(0)
"""

options : options

render: () -> """
<div class="container">
    <div class="app-badge"></div>
    <div class="top-row">
        <div class="album-art">
            <div class="pause-overlay"><div class="pp-icon pp-pause"></div><div class="pp-icon pp-play"></div></div>
        </div>
        <div class="track-info">
            <div class="artist-name"></div>
            <div class="song-name"></div>
            <div class="album-name"></div>
        </div>
        <div class="divider"></div>
        <div class="controls">
            <div class="status status-shuffle"></div>
            <div class="ctrl ctrl-prev"></div>
            <div class="ctrl ctrl-playpause"><span class="cpp-play"></span><span class="cpp-pause"></span></div>
            <div class="ctrl ctrl-next"></div>
            <div class="status status-repeat"></div>
        </div>
    </div>
    <div class="bottom-row">
        <div class="time-elapsed">0:00</div>
        <div class="bar-container">
            <div class="bar bar-progress"></div>
        </div>
        <div class="time-remaining">-0:00</div>
    </div>
</div>
"""

# Apply marquee scrolling to an element when its inner text overflows.
applyMarquee: (div, selector, html) ->
  el = div.find(selector)
  node = el[0]
  return unless node
  if el.attr('data-marquee-html') isnt html
    el.attr('data-marquee-html', html)
    el.html("<span class=\"marquee-text\">#{html}</span>")
  inner = el.find('.marquee-text')[0]
  return unless inner
  overflow = inner.scrollWidth - node.clientWidth
  if overflow > 0
    duration = Math.max(14, Math.round((overflow + 80) / 10))
    node.style.setProperty('--marquee-distance', "-#{overflow}px")
    node.style.setProperty('--marquee-duration', "#{duration}s")
    el.addClass('is-marquee')
  else
    el.removeClass('is-marquee')
    node.style.removeProperty('--marquee-distance')
    node.style.removeProperty('--marquee-duration')

# Format a duration in seconds as H:MM:SS (when >= 1h) or M:SS.
formatTime: (t, prefix = '') ->
  h = Math.floor(t / 3600)
  m = Math.floor((t % 3600) / 60)
  s = t % 60
  sStr = if s < 10 then "0#{s}" else "#{s}"
  if h > 0
    mStr = if m < 10 then "0#{m}" else "#{m}"
    "#{prefix}#{h}:#{mStr}:#{sStr}"
  else
    "#{prefix}#{m}:#{sStr}"

# Update the rendered output.
update: (output, domEl) ->

  # Tell layout-controller.widget which screen edge this widget was written for, so it
  # can manage it without first dragging it into place. The controller stacks a column
  # from the top by default; this widget sits at the foot of the screen, and saying so
  # is what lets it be packed like anything else instead of opting out entirely.
  #
  # Only a default: once the widget has been dragged, where it was dropped wins and
  # this is ignored. Set on every update rather than once, because Übersicht builds a
  # fresh element when the widget reloads and a stale attribute would not survive.
  domEl.setAttribute? 'data-layout-anchor',
    if options.verticalPosition is 'bottom' then 'bottom' else 'top'

  div = $(domEl)

  # Bind transport clicks once. Classic widgets have no `run` global, so POST the
  # command to Übersicht's same-origin /run/ endpoint; control.applescript acts on
  # whichever player (Music/Spotify) is active.
  #
  # Delegated from the widget's root element rather than bound to the buttons: the
  # root is the one node Übersicht keeps, and everything inside it is thrown away and
  # rebuilt from render() the first time the widget recovers from an error tick (any
  # stderr from the command counts as one). Handlers sitting on the buttons go with
  # that markup, and since the widget object survives, a plain "bound already" flag
  # stays set and they are never restored: the controls go quietly dead until the
  # widget is reloaded. Delegation lives on the surviving node, so it outlasts any
  # number of re-renders. The guard remembers the element, not a boolean, so a
  # genuinely new root still gets its own handlers.
  unless @_ppBoundEl is domEl
    @_ppBoundEl = domEl
    self = this
    # Leading-edge throttle, per command: the first click fires immediately, and
    # repeats within the window are ignored, so mashing a control can't flood the
    # /run/ endpoint with osascript processes. Returns true only when it actually fired.
    lastSent = {}
    THROTTLE = 300   # ms
    send = (cmd) ->
      now = Date.now()
      return false if lastSent[cmd] and (now - lastSent[cmd]) < THROTTLE
      lastSent[cmd] = now
      fetch '/run/', method: 'POST', body: "osascript 'music.widget/lib/control.applescript' #{cmd}"
      true
    # Flip the optimistic paused state only if the command wasn't throttled.
    togglePlay = ->
      div.find('.container').toggleClass('is-paused') if send('playpause')
    # Single-column layout (controls hidden): the album art is the play/pause
    # button. With controls shown it's just artwork, so the click does nothing.
    div.on 'click', '.album-art', ->
      togglePlay() if self.options.controls is false
    # Transport buttons (shown when controls are enabled).
    div.on 'click', '.ctrl-prev', -> send('previous')
    div.on 'click', '.ctrl-next', -> send('next')
    div.on 'click', '.ctrl-playpause', -> togglePlay()
    # Shuffle toggles (optimistically, only if it fired); repeat cycles server-side,
    # the 1s poll updates its glyph/lit state (Music has 3 states, no safe guess).
    div.on 'click', '.status-shuffle', ->
      div.find('.status-shuffle').toggleClass('on') if send('shuffle')
    div.on 'click', '.status-repeat', -> send('repeat')
    # Clicking the app badge opens (or focuses) whichever app is playing.
    appBundles = { Music: 'com.apple.Music', Spotify: 'com.spotify.client' }
    div.on 'click', '.app-badge', ->
      bid = appBundles[self._musicApp]
      fetch '/run/', method: 'POST', body: "open -b '#{bid}'" if bid

  # if widget enabled
  if @options.widgetEnabled

    # if not output then hide the widget
    if !output
      div.animate({opacity: 0}, 1000, 'swing').hide(1)
      return

    # gather script values
    values = output.slice(0,-1).split(" @ ")
    songDuration = values[4]
    currentPosition = values[5]
    coverURL = values[6]
    isLoved = values[8]
    playerState = values[10] or 'playing'
    shuffleOn = values[11]
    repeatMode = values[12]   # off | one | all (Spotify: off | all)
    musicApp = values[13]     # Music | Spotify (drives the square-layout app badge)

    songNameHtml = values[1]
    if isLoved == 'true'
      songNameHtml = songNameHtml + '<span class="is-loved">&starf;</span>'

    songYear = values[3]
    albumHtml = values[2]
    if songYear and songYear isnt '0' and songYear isnt 'NA'
      albumHtml += " &bull; #{songYear}"

    defaultUrl = 'music.widget/lib/default.png'
    newBg = if not coverURL or coverURL is 'NA'
      "url(#{defaultUrl})"
    else
      # layer default underneath so it shows if coverURL fails to load
      "url(#{coverURL}), url(#{defaultUrl})"

    # cross-fade only the artwork + track info when the track actually changes.
    # The divider and transport controls sit in the same row but must NOT fade,
    # they represent playback state, not the song, so they hold steady.
    songId = "#{values[0]}|#{values[1]}|#{values[2]}"
    self = this
    applyTrackInfo = ->
      self.applyMarquee(div, '.artist-name', values[0])
      self.applyMarquee(div, '.song-name', songNameHtml)
      self.applyMarquee(div, '.album-name', albumHtml)
      div.find('.album-art').css('background-image', newBg)

    if @_lastSongId? and @_lastSongId isnt songId
      info = div.find('.album-art, .track-info')
      # .promise().done fires once for the whole set (not once per element).
      info.stop(true).animate({opacity: 0}, 250).promise().done ->
        applyTrackInfo()
        info.animate {opacity: 1}, 250
    else
      applyTrackInfo()
    @_lastSongId = songId

    # set progress bar width, measured from container so it tracks layout changes
    barContainer = div.find('.bar-container')
    barWidth = barContainer[0].clientWidth
    songProgress = (currentPosition / songDuration) * barWidth
    div.find('.bar-progress').css width: songProgress

    # format time, clamped to 0
    elapsed = parseInt(currentPosition, 10)
    elapsed = 0 if isNaN(elapsed) or elapsed < 0
    total = parseInt(songDuration, 10)
    total = 0 if isNaN(total) or total < 0
    remaining = Math.max(0, total - elapsed)

    div.find('.time-elapsed').text(@formatTime(elapsed))
    div.find('.time-remaining').text(@formatTime(remaining, '-'))

    mode = if @options.showBothTimes then 'both'
    else if @options.showRemainingTime then 'remaining'
    else 'elapsed'
    container = div.find('.container')
    container
      .removeClass('mode-elapsed mode-remaining mode-both')
      .addClass("mode-#{mode}")
    # Layout classes. 'vertical' and 'square' are one-column stacks (the shared
    # `layout-stacked` class); they apply whether or not controls are shown.
    # 'horizontal' with controls hidden collapses to a single column (the default
    # no-class state). `show-controls` gates the controls row + divider.
    showControls = @options.controls isnt false
    isVertical = @options.layout is 'vertical'
    isSquare = @options.layout is 'square'
    isStacked = isVertical or isSquare
    container.toggleClass('layout-vertical', isVertical)
    container.toggleClass('layout-square', isSquare)
    container.toggleClass('layout-stacked', isStacked)
    container.toggleClass('layout-horizontal', showControls and not isStacked)
    container.toggleClass('show-controls', showControls)
    # Compact bar-tuck only applies to the collapsed single-column horizontal
    # layout, never with controls shown, and never in a stacked layout.
    container.toggleClass('layout-compact', @options.progressBarPosition is 'compact' and not showControls and not isStacked)
    container.toggleClass('no-time', not @options.showTime)
    container.toggleClass('show-app-icon', @options.showAppIcon isnt false)
    # App badge (square layout): show the icon of whichever app is playing, and
    # remember it so the badge's click handler can open that app.
    @_musicApp = musicApp
    if musicApp and musicApp isnt 'NA'
      slug = musicApp.toLowerCase()
      badgeUrl = "url(music.widget/lib/icons/app-#{slug}.png)"
      $badge = div.find('.app-badge')
      $badge.css('background-image', badgeUrl) if $badge.css('background-image') isnt badgeUrl
    # Track-text alignment (left | center | right); default to center on a bad value.
    align = if @options.contentAlign in ['left', 'center', 'right'] then @options.contentAlign else 'center'
    container
      .removeClass('align-left align-center align-right')
      .addClass("align-#{align}")
    if playerState is 'paused'
      container.addClass('is-paused')
    else
      container.removeClass('is-paused')

    # Shuffle / repeat status: lit when active, dim when off. The repeat glyph
    # swaps to repeat.1 for "repeat one" (Music only).
    div.find('.status-shuffle').toggleClass('on', shuffleOn is 'true')
    $rp = div.find('.status-repeat')
    if @_lastRepeat isnt repeatMode
      @_lastRepeat = repeatMode
      img = if repeatMode is 'one' then 'repeat.1' else 'repeat'
      $rp.css('-webkit-mask-image', "url(music.widget/lib/icons/#{img}.ink.png)")
      $rp.css('mask-image', "url(music.widget/lib/icons/#{img}.ink.png)")
    $rp.toggleClass('on', repeatMode isnt 'off')

    # show the widget
    div.show(1).animate({opacity: 1}, 250, 'swing')

  # hide widget if disabled
  else
    div.hide()
