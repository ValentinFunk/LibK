GLib.Transfers = {}
GLib.Transfers.InboundTransfers  = {}
GLib.Transfers.OutboundTransfers = {}
GLib.Transfers.Requests = {}
GLib.Transfers.Handlers = {}
GLib.Transfers.InitialPacketHandlers = {}
GLib.Transfers.RequestHandlers = {}
GLib.Transfers.NextTransferId = 1

if SERVER then
	util.AddNetworkString ("glib_cancel_transfer")
	util.AddNetworkString ("glib_transfer")
	util.AddNetworkString ("glib_transfer_request")
	util.AddNetworkString ("glib_transfer_request_response")
end

local function EndNetMessage (userId)
	if CLIENT then
		net.SendToServer ()
	elseif SERVER then
		if userId == GLib.GetEveryoneId () then
			net.Broadcast ()
		else
			for _, v in ipairs (player.GetAll ()) do
				if GLib.GetPlayerId (v) == userId then
					net.Send (v)
					return
				end
			end
			
			GLib.Error ("GLib.Transfers : Unknown userId " .. userId .. "!")
		end
	end
end

net.Receive ("glib_cancel_transfer",
	function (_, ply)
		local userId = SERVER and GLib.GetPlayerId (ply) or "Server"
		
		local transferId = net.ReadUInt (32)
		
		local outboundTransfer = GLib.Transfers.OutboundTransfers [userId .. "/" .. transferId]
		if not outboundTransfer then return end
		
		-- print ("GLib.Transfers : Outbound transfer " .. outboundTransfer:GetDisplayId () .. " cancelled.")
		GLib.Transfers.OutboundTransfers [userId .. "/" .. transferId] = nil
	end
)

net.Receive ("glib_transfer",
	function (_, ply)
		local userId = SERVER and GLib.GetPlayerId (ply) or "Server"
		local messageType = net.ReadUInt (8)
		local transferId = net.ReadUInt (32)
		
		local inboundTransfer = nil
		
		if messageType == 1 then
			-- New inbound transfer
			local channelName = net.ReadString ()
			
			if not GLib.Transfers.Handlers [channelName] then
				-- Unknown channel, do not want
				GLib.Transfers.CancelUnknownTransfer (userId, transferId)
				return
			end
			
			if GLib.Transfers.InboundTransfers [userId .. "/" .. transferId] and
			   GLib.Transfers.InboundTransfers [userId .. "/" .. transferId]:GetRequestId () then
				-- Transfer was previously requested
				inboundTransfer = GLib.Transfers.InboundTransfers [userId .. "/" .. transferId]
			else
				-- New transfer
				inboundTransfer = GLib.Transfers.InboundTransfer (transferId)
				inboundTransfer:SetChannelName (channelName)
				inboundTransfer:SetSourceId (userId)
				GLib.Transfers.InboundTransfers [userId .. "/" .. transferId] = inboundTransfer
			end
			
			-- Deserialize first chunk
			local length = net.ReadUInt (32)
			local inBuffer = GLib.StringInBuffer (net.ReadData (length))
			inboundTransfer:DeserializeFirstChunk (inBuffer)
			
			-- Call initial packet handler
			local initialPacketHandler = GLib.Transfers.InitialPacketHandlers [channelName]
			if initialPacketHandler then
				local continueTransfer = initialPacketHandler (userId, inboundTransfer:GetFirstChunk ())
				if continueTransfer == false then
					GLib.Transfers.CancelInboundTransfer (userId, transferId)
					return
				end
			end
		elseif messageType == 2 then
			-- Continuation of a transfer
			inboundTransfer = GLib.Transfers.InboundTransfers [userId .. "/" .. transferId]
			
			if not inboundTransfer then
				-- Unknown transfer, do not want
				GLib.Transfers.CancelUnknownInboundTransfer (userId, transferId)
				return
			end
			
			-- Deserialize chunk
			local length = net.ReadUInt (32)
			local inBuffer = GLib.StringInBuffer (net.ReadData (length))
			inboundTransfer:DeserializeNextChunk (inBuffer)
		end
		
		if inboundTransfer:IsFinished () then
			-- Transfer finished
			GLib.Transfers.InboundTransfers [userId .. "/" .. inboundTransfer:GetId ()] = nil
			
			-- Call handlers
			inboundTransfer:DispatchEvent ("Finished")
			local handler = GLib.Transfers.Handlers [inboundTransfer:GetChannelName ()]
			if handler then
				handler (inboundTransfer:GetSourceId (), inboundTransfer:GetData ())
			end
		end
	end
)

local function HandleTransferRequest (userId, channelName, requestId, data)
	local requestHandler = GLib.Transfers.RequestHandlers [channelName]
	local requestAccepted, responseData = false, ""
	if requestHandler then
		requestAccepted, responseData = requestHandler (userId, data)
		responseData = responseData or ""
		responseData = tostring (responseData)
	end
	
	net.Start ("glib_transfer_request_response")
	net.WriteUInt (requestId, 32)
	
	if requestAccepted then
		local outboundTransfer = GLib.Transfers.Send (userId, channelName, responseData)
		
		net.WriteUInt (1, 8)
		net.WriteUInt (outboundTransfer:GetId (), 32)
	else
		net.WriteUInt (0, 8)
		net.WriteUInt (#responseData, 16)
		net.WriteData (responseData, #responseData)
	end
	EndNetMessage (userId)
end

net.Receive ("glib_transfer_request",
	function (_, ply)
		local userId = SERVER and GLib.GetPlayerId (ply) or "Server"
		
		local channelName = net.ReadString ()
		local requestId = net.ReadUInt (32)
		local dataLength = net.ReadUInt (16)
		local data = net.ReadData (dataLength)
		
		HandleTransferRequest (userId, channelName, requestId, data)
	end
)

net.Receive ("glib_transfer_request_response",
	function (_, ply)
		local userId = SERVER and GLib.GetPlayerId (ply) or "Server"
		
		local requestId = net.ReadUInt (32)
		local requestAccepted = net.ReadUInt (8) == 1
		local transferId = nil
		local rejectionData = nil
		
		if requestAccepted then
			transferId = net.ReadUInt (32)
		else
			local rejectionDataLength = net.ReadUInt (16)
			rejectionData = net.ReadData (rejectionDataLength)
		end
		
		local inboundTransfer = GLib.Transfers.Requests [userId .. "/" .. requestId]
		GLib.Transfers.Requests [userId .. "/" .. requestId] = nil
		
		if not inboundTransfer then
			-- Cancel the transfer, we have no knowledge of this place.
			if requestAccepted then
				GLib.Transfers.CancelUnknownInboundTransfer (userId, transferId)
			end
			return
		end
		
		if requestAccepted then
			inboundTransfer:SetId (transferId)
			GLib.Transfers.InboundTransfers [userId .. "/" .. inboundTransfer:GetId ()] = inboundTransfer
			inboundTransfer:DispatchEvent ("RequestAccepted", inboundTransfer:GetId ())
		else
			inboundTransfer:DispatchEvent ("RequestRejected", rejectionData)
		end
	end
)

timer.Create ("GLib.Transfers", 1, 0,
	function ()
		for _, inboundTransfer in pairs (GLib.Transfers.InboundTransfers) do
			if not inboundTransfer:IsSourceValid () then
				GLib.Transfers.InboundTransfers [inboundTransfer:GetSourceId () .. "/" .. inboundTransfer:GetId ()] = nil
			end
		end
		
		for _, outboundTransfer in pairs (GLib.Transfers.OutboundTransfers) do
			if not outboundTransfer:IsDestinationValid () then
				GLib.Transfers.OutboundTransfers [outboundTransfer:GetDestinationId () .. "/" .. outboundTransfer:GetId ()] = nil
			else
				local outBuffer = GLib.StringOutBuffer ()
				
				net.Start ("glib_transfer")				
					if not outboundTransfer:IsStarted () then
						net.WriteUInt (1, 8)
						net.WriteUInt (outboundTransfer:GetId (), 32)
						net.WriteString (outboundTransfer:GetChannelName ())
						outboundTransfer:SerializeFirstChunk (outBuffer)
					else
						net.WriteUInt (2, 8)
						net.WriteUInt (outboundTransfer:GetId (), 32)
						outboundTransfer:SerializeNextChunk (outBuffer)
					end
					net.WriteUInt (#outBuffer:GetString (), 32)
					net.WriteData (outBuffer:GetString (), #outBuffer:GetString ())
				EndNetMessage (outboundTransfer:GetDestinationId ())
				
				if outboundTransfer:IsFinished () then
					GLib.Transfers.OutboundTransfers [outboundTransfer:GetDestinationId () .. "/" .. outboundTransfer:GetId ()] = nil
				end
			end
		end
	end
)

function GLib.Transfers.CancelInboundTransfer (userId, transferId)
	if not GLib.Transfers.InboundTransfers [userId .. "/" .. transferId] then
		GLib.Error ("GLib.Transferse.CancelInboundTransfer : This function should not be used for unknown inbound transfers.")
	end
	GLib.Transfers.InboundTransfers [userId .. "/" .. transferId] = nil
	GLib.Transfers.CancelUnknownInboundTransfer (userId, transferId)
end

function GLib.Transfers.CancelUnknownInboundTransfer (userId, transferId)
	net.Start ("glib_cancel_transfer")
		net.WriteUInt (transferId, 32)
	EndNetMessage (userId)
end

function GLib.Transfers.Send (userId, channelName, data)
	local outboundTransfer = GLib.Transfers.OutboundTransfer (GLib.Transfers.NextTransferId, data)
	GLib.Transfers.NextTransferId = GLib.Transfers.NextTransferId + 1
	GLib.Transfers.OutboundTransfers [userId .. "/" .. outboundTransfer:GetId ()] = outboundTransfer
	outboundTransfer:SetChannelName (channelName)
	outboundTransfer:SetDestinationId (userId)
	
	return outboundTransfer
end

function GLib.Transfers.Request (userId, channelName, data)
	local inboundTransfer = GLib.Transfers.InboundTransfer ()
	inboundTransfer:SetRequestId (GLib.Transfers.NextTransferId)
	GLib.Transfers.NextTransferId = GLib.Transfers.NextTransferId + 1
	GLib.Transfers.Requests [userId .. "/" .. inboundTransfer:GetRequestId ()] = inboundTransfer
	inboundTransfer:SetChannelName (channelName)
	inboundTransfer:SetSourceId (userId)
	
	if util.NetworkStringToID ("glib_transfer_request") == 0 then
		GLib.CallDelayed (
			function ()
				GLib.Transfers.Requests [userId .. "/" .. inboundTransfer:GetRequestId ()] = nil
				inboundTransfer:DispatchEvent ("RequestRejected", "")
			end
		)
	else
		data = data or ""
		
		net.Start ("glib_transfer_request")
			net.WriteString (channelName)
			net.WriteUInt (inboundTransfer:GetRequestId (), 32)
			net.WriteUInt (#data, 16)
			net.WriteData (data, #data)
		EndNetMessage (userId)
	end
	
	return inboundTransfer
end

function GLib.Transfers.RegisterHandler (channelName, handler)
	GLib.Transfers.Handlers [channelName] = handler
end

function GLib.Transfers.RegisterInitialPacketHandler (channelName, handler)
	GLib.Transfers.InitialPacketHandlers [channelName] = handler
end

function GLib.Transfers.RegisterRequestHandler (channelName, handler)
	GLib.Transfers.RequestHandlers [channelName] = handler
end