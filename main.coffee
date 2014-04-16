limit = 0xffff
wsUrl = "ws://echo.websocket.org"

msgLength = 0xfff
mps = 10

ws = null

testRunning = no

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

  sendLog = $('#send_console')
  recLog = $('#receive_console')

  lengthInput.val msgLength
  lengthInput.on 'keyup', ->
    msgLength = lengthInput.val()

  mpsInput.val mps
  mpsInput.on 'keyup', ->
    mps = mpsInput.val() || 1

  logReceived = (string) ->
    recLog.text "#{Date.now()}: #{string}"

  logSent = (string) ->
    sendLog.text "#{Date.now()}: #{string}"

  wsLoop = ->
    if not testRunning
      return

    # calculate the timeout for next request
    timeout = 1000 / mps
    msg = randomString msgLength
    ws.send msg
    logSent "#{msgLength} chars long message sent: #{msg.substr(0, 15)}"
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
      logReceived "WS message (#{e.data.length} chars) received: #{e.data.substr(0, 20)}"
    ws.onerror = (e)->
      logReceived.parent().append "<div>#{Date.now()}: Error: #{e.data}</div>"

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