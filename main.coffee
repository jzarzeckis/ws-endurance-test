limit = 0xffff
wsUrl = "ws://echo.websocket.org"
controlString = "Random"

msgLength = 0xfff
mps = 10

ws = null

testRunning = no

receiveTimeStampStack = []

randomString = do ->
  availableChars = []
  for code in [33..126]
    availableChars.push String.fromCharCode code
  availableLen = availableChars.length
  (length)->
    if length < 1
      return
    str = ""
    while length--
      str = str + availableChars[Math.round(Math.random() * availableLen)]
    str



$ ->
  startBtn = $('#start')
  stopBtn = $('#stop')
  lengthInput = $('#msg_length')
  mpsInput = $('#mps')
  urlSelect = $('#ws_url')
  controlSelect = $('#control_msg')

  sendLog = $('#send_console')
  recLog = $('#receive_console')

  fpsMeter = $('#fps_meter')

  lengthInput.val msgLength
  lengthInput.on 'keyup', ->
    msgLength = lengthInput.val()

  mpsInput.val mps
  mpsInput.on 'keyup', ->
    mps = mpsInput.val() || 1

  urlSelect.val wsUrl
  urlSelect.on 'change', ->
    wsUrl = urlSelect.val()

  controlSelect.val controlString
  controlSelect.on 'change', ->
    controlString = controlSelect.val()

  stampReceived = do ->
    # finds the index, up to which items can be removed from stack (items older than 1s)
    findLimit = (oldStamp)->
      end = -1
      for stamp, idx in receiveTimeStampStack
        if stamp > oldStamp
          return idx # all elements until thix index will be removed via array splice
        end = idx
      return end + 1 # appears that splice can remove up to the last element
    ->
      stamp = Date.now()
      old = stamp - 1000
      removableCount = findLimit old
      receiveTimeStampStack.splice 0, removableCount
      receiveTimeStampStack.push stamp
      fpsMeter.text receiveTimeStampStack.length


  logReceived = (string) ->
    stampReceived()
    recLog.text "#{Date.now()}: #{string}"

  logSent = (string) ->
    sendLog.text "#{Date.now()}: #{string}"

  wsLoop = ->
    if not testRunning
      return

    # calculate the timeout for next request
    timeout = 1000 / mps
    msg = if controlString is "Random" then randomString msgLength else controlString
    ws.send msg
    logSent "#{msg.length} chars long message sent: #{msg.substr(0, 15)}"
    window.setTimeout wsLoop, timeout


  startTest = ->
    ws = new WebSocket wsUrl
    ws.onopen = ->
      logReceived "Websocket open"
      testRunning = yes
      wsLoop()
    ws.onclose = ->
      logReceived "Websocket closed"
      stopTest()
    ws.onmessage = (e)->
      logReceived "WS message (#{e.data.length} chars) received: #{e.data.substr?(0, 20)}"
    ws.onerror = (e)->
      recLog.parent().append "<div>#{Date.now()}: Error: #{e.data}</div>"

  stopTest = ->
    testRunning = no
    if ws and ws.readyState is ws.OPEN
      ws.close()



  startBtn.on 'click', (e)->
    e.preventDefault()
    startTest()

  stopBtn.on 'click', (e)->
    e.preventDefault()
    stopTest()