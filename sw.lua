-- Global variables
text = ""
chatLog = {}

-- Keyboard variables
kb = {
    "1234567890",
    "qwertyuiop/*",
    "asdfghjkl+-",
    "zxcvbnm ?."
}
res = ""
enter = false
holdThreshold = 30
hold = 0
holdX = 0
holdY = 0

-- Mouse input variables
inputX = 0
inputY = 0
isPressed = false
mousePreviouslyPressed = false

-- Keyboard position and size (as properties)
keyboard_x = property.getNumber("keyboard_x")
keyboard_y = property.getNumber("keyboard_y")
keyboard_width = property.getNumber("keyboard_width")
keyboard_height = property.getNumber("keyboard_height")

-- Customizable variables
textSize = property.getNumber("text_size")                -- Size of text for chat log and keys
chatLogSpacing = property.getNumber("chat_log_spacing")           -- Distance between each chat log entry
enterKeyText = property.getText("enter_text")       -- Text for the Enter key
backspaceKeyText = property.getText("back")     -- Text for the Backspace key

function onTick()
    -- Mouse input handling
    inputX = input.getNumber(3)
    inputY = input.getNumber(4)
    isPressed = input.getBool(1)

    -- Keyboard hold detection
    if isPressed then
        hold = hold + 1
        holdX = inputX
        holdY = inputY
    else
        hold = 0
    end

    -- Reset enter flag when output index changes
    outputIndex = input.getNumber(32)
    if outputIndex > #res then
        enter = false
    end

    -- Output if enter is pressed
    if enter then
        output.setBool(1, true)
        output.setNumber(1, string.byte(res, outputIndex, outputIndex))
        output.setNumber(2, #res)
    else
        output.setBool(1, false)
        output.setNumber(1, 0)
        output.setNumber(2, 0)
    end

    -- Check for mouse click debounce
    mousePreviouslyPressed = isPressed
end

-- Function to check if a point is within a rectangle
function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
    return x > rectX and y > rectY and x < rectX + rectW and y < rectY + rectH
end

-- Function to draw a button and handle click events
function drawButton(x, y, w, h, content, recall, holdRecall, param)
    screen.setColor(30, 30, 30)
    onButton = false

    if isPressed and isPointInRectangle(inputX, inputY, x - 1, y, w, h) then
        onButton = true
        screen.setColor(100, 100, 100)
        if hold > holdThreshold then
            screen.setColor(200, 0, 0)
        end
    else
        if hold > holdThreshold and holdRecall and isPointInRectangle(holdX, holdY, x - 1, y, w, h) then
            holdRecall(param)
            hold = 0
            holdX = 0
            holdY = 0
        elseif isPointInRectangle(holdX, holdY, x - 1, y, w, h) then
            recall(param)
            hold = 0
            holdX = 0
            holdY = 0
        end
    end

    screen.drawRectF(x, y, w, h)
    screen.setColor(255, 255, 255)
    screen.drawTextBox(x + 1, y + 1, w - 1, h - 1, content, 0, 0)

    return onButton
end

-- Function to append a character to the current input text
function appendChar(char)
    res = res .. char
end

-- Function to handle backspace
function backSpace()
    res = string.sub(res, 1, -2)
end

-- Function to handle enter key press
function enterKey()
    enter = true
    if res ~= "" then
        sendChatMessage(res)
        res = ""
    end
end

-- Function to URL encode a string
function urlEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "%%20")
    end
    return str
end

-- Function to send a chat message
function sendChatMessage(message)
    local encodedMessage = urlEncode(message)
    table.insert(chatLog, { type = "user", message = message })
    async.httpGet(5000, "/chat?text=" .. encodedMessage)
end

-- Function to draw the chat log above the keyboard
function drawChatLog(x, y, width)
    local currentY = y - chatLogSpacing - 5

    for i = #chatLog, 1, -1 do
        local entry = chatLog[i]
        if entry.type == "user" then
            screen.drawTextBox(x, currentY, width - 5, textSize, "U: " .. entry.message, 0, 0)
        else
            screen.drawTextBox(x, currentY, width - 5, textSize, "A: " .. entry.message, 0, 0)
        end
        currentY = currentY - chatLogSpacing
    end
end

-- Draw the keyboard and chat
function onDraw()
    local w = screen.getWidth()
    local h = screen.getHeight()

    -- Draw the chat log (above the keyboard)
    drawChatLog(5, keyboard_y - 5, w - 10)

    -- Draw keyboard keys
    local yShift = keyboard_y + 7
    local xShift = { 7, 7, 9, 11 }

    drawButton(w - 20, keyboard_y, 12, 5, backspaceKeyText, backSpace, false, false)
    drawButton(xShift[1], keyboard_y, 12, 5, enterKeyText, enterKey, false, false)

    for yAxis = 1, 4 do
        for xAxis = 1, #kb[yAxis] do
            local chr = string.sub(kb[yAxis], xAxis, xAxis)
            drawButton(xShift[yAxis] + (xAxis - 1) * 5, yShift + (yAxis - 1) * 6, 4, 5, chr, appendChar, false, chr)
        end
    end

    -- Draw the current text input
    screen.drawText(5, keyboard_y - 15, res)
end

-- Callback for receiving HTTP responses
function httpReply(port, request_body, response_body)
    if port == 5000 then
        table.insert(chatLog, { type = "server", message = response_body })
    end
end
