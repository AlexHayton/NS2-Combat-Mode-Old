//=============================================================================
//
// lua/Chat.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// color, playername, color, message
local chatMessages = { }
local enteringChatMessage = false
local teamOnlyChat = false

/**
 * Returns true if the user is currently holding down the button to record for
 * voice chat.
 */
function ChatUI_IsVoiceChatActive()
    return Client.IsVoiceRecordingActive()
end

function ChatUI_GetMessages()

    local uiChatMessages = {}
    
    if(table.maxn(chatMessages) > 0) then
    
        table.copy(chatMessages, uiChatMessages)
        chatMessages = {}
        
    end
        
    return uiChatMessages
    
end

// Return true if we want the UI to take key input for chat
function ChatUI_EnteringChatMessage()
    return enteringChatMessage
end

// Return string prefix to display in front of the chat input
function ChatUI_GetChatMessageType()

    if teamOnlyChat then
        return "Team: "
    end
    
    return "All: "
    
end

function ChatUI_GetChatMessageTypeColor()
    return kChatPrefixTextColor
end

function ChatUI_GetChatMessageBodyColor()
    return kChatTextColor
end

// Called when player hits return after entering a chat message. Send it 
// to the server.
function ChatUI_SubmitChatMessageBody(chatMessage)
    
    // Quote string so spacing doesn't come through as multiple arguments
    if chatMessage ~= nil and string.len(chatMessage) > 0 then
    
        Client.ConsoleCommand(string.format("%s \"%s\"", ConditionalValue(teamOnlyChat, "teamsay", "say"), chatMessage))

        teamOnlyChat = false
        
    end
    
    enteringChatMessage = false
    
end

// Client should call this when player hits key to enter a chat message
function ChatUI_EnterChatMessage(teamOnly)

    if not enteringChatMessage then
    
        enteringChatMessage = true
        teamOnlyChat = teamOnly
        
    end
    
end

/**
 * Called when chat message is clicked on commander screen
 */
function ChatUI_ClickedChatMessage(entityId)

end

/**
 * This function is called when the client receives a chat message.
 */
function OnCommandChat(teamOnly, playerName, locationId, teamNumber, message)

    local player = Client.GetLocalPlayer()

    if player then
        // color, playername, color, message        
        table.insert(chatMessages, GetColorForTeamNumber(tonumber(teamNumber)))

        // Tack on location name if any
        local locationNameText = ""
        
        // Lookup location name from passed in id
        local locationName = ""
        locationId = tonumber(locationId)
        if locationId ~= 0 then
            locationNameText = string.format("(Team, %s) ", Shared.GetString(locationId))
        end
        
        // Pre-pend "team" or "all"
        local preMessageString = string.format("%s%s: ", ConditionalValue(tonumber(teamOnly) == 1, locationNameText, "(All) "), DecodeStringFromNetwork(playerName), locationNameText)

        table.insert(chatMessages, preMessageString)
        table.insert(chatMessages, kChatTextColor)
        
        table.insert(chatMessages, message)
        
        // reserved for possible texture name
        table.insert(chatMessages, "")
        // texture x
        table.insert(chatMessages, 0)
        // texture y
        table.insert(chatMessages, 0)
        // entity id
        table.insert(chatMessages, 0)
        
        Shared.PlaySound(self, player:GetChatSound())
        
        // Only print to log if the client isn't running a local server
        // which has already printed to log.
        if not Client.GetIsRunningServer() then
            local prefixText = "Chat All"
            if tonumber(teamOnly) == 1 then
                prefixText = "Chat Team " .. tostring(teamNumber)
            end
            Shared.Message(prefixText .. " - " .. DecodeStringFromNetwork(playerName) .. ": " .. message)
        end
    end
end

/**
 * Returns true if in commander mode, false otherwise
 */
function ChatUI_IsCommanderMode()
    local player = Client.GetLocalPlayer()
    return player ~= nil and player:isa("Commander")
end

function PlayerUI_ChatIconsImage()
    return "chat_icons"
end

function PlayerUI_ChatIconWidth()
    return 16
end

function PlayerUI_ChatIconHeight()
    return 16
end

function PlayerUI_GetChatMessageText(messageIndex)
    return chatMessages[messageIndex].message
end

function PlayerUI_GetChatMessageFrom(messageIndex)
    return chatMessages[messageIndex].name
end

function PlayerUI_HasChatMessageIcon(messageIndex)
    return false
end

function PlayerUI_GetChatIconXOffset(messageIndex)
    return 0
end

function PlayerUI_GetChatIconYOffset(messageIndex)
    return 0
end

function PlayerUI_GetNumAvailableChatMessages()
    return table.maxn( chatMessages )
end

function PlayerUI_GetChatColor(messageIndex)
    return 0xFFFFFF
end

Event.Hook("Console_chat", OnCommandChat)

