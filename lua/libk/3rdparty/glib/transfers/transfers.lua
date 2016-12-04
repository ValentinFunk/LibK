local vnet = GLib.vnet

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

local function EndPacket (packet, userId)
	if CLIENT then
		packet:AddServer()
		packet:Send()
	elseif SERVER then
		if userId == GLib.GetEveryoneId () then
			packet:Broadcast()
		else
			for _, v in ipairs (player.GetAll ()) do
				if GLib.GetPlayerId (v) == userId then
					packet:AddTargets (v)
					packet:Send()
					return
				end
			end
		end
	end
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

vnet.Watch("glib_transfer", function(packet)
	local userId = isbool(packet.Source) and "Server" or GLib.GetPlayerId (packet.Source)

	local messageType = packet:Int ()
	local transferId = packet:Int ()

	local inboundTransfer = nil

	if messageType == 1 then
		-- New inbound transfer
		local channelName = packet:String ()

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
		local inBuffer = GLib.StringInBuffer (packet:String())
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
		local inBuffer = GLib.StringInBuffer (packet:String())
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
end)

local function HandleTransferRequest (userId, channelName, requestId, data)
	local requestHandler = GLib.Transfers.RequestHandlers [channelName]
	local requestAccepted, responseData = false, ""
	if requestHandler then
		requestAccepted, responseData = requestHandler (userId, data)
		responseData = responseData or ""
		responseData = tostring (responseData)
	end

	local packet = vnet.CreatePacket("glib_transfer_request_response")
	packet:Int(requestId)

	if requestAccepted then
		local outboundTransfer = GLib.Transfers.Send (userId, channelName, responseData)
		packet:Int (1)
		packet:Int (outboundTransfer:GetId ())
	else
		packet:Int (0)
		packet:String (responseData)
	end
	local ply
	for k, v in pairs(player.GetAll()) do
		if GLib.GetPlayerId (v) == userId then
			ply = v
			break
		end
	end
	packet:AddTargets(ply)
	packet:Send()
end

vnet.Watch("glib_transfer_request", function(packet)
	local userId = isbool(packet.Source) and "Server" or GLib.GetPlayerId (packet.Source)

	local channelName = packet:String()
	local requestId = packet:Int()
	local data = packet:String()

	HandleTransferRequest (userId, channelName, requestId, data)
end )

vnet.Watch("glib_transfer_request_response", function(packet)
	local userId = isbool(packet.Source) and "Server" or GLib.GetPlayerId (packet.Source)

	local requestId = packet:Int()
	local requestAccepted = packet:Int() == 1
	local transferId = nil
	local rejectionData = nil

	if requestAccepted then
		transferId = packet:Int()
	else
		rejectionData = packet:String()
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
end )

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

				local packet = vnet.CreatePacket("glib_transfer")
					if not outboundTransfer:IsStarted () then
						packet:Int(1)
						packet:Int(outboundTransfer:GetId ())
						packet:String (outboundTransfer:GetChannelName ())
						outboundTransfer:SerializeFirstChunk (outBuffer)
					else
						packet:Int(2)
						packet:Int (outboundTransfer:GetId ())
						outboundTransfer:SerializeNextChunk (outBuffer)
					end
					packet:String (outBuffer:GetString ())
				EndPacket(packet, outboundTransfer:GetDestinationId ())

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

		local packet = vnet.CreatePacket("glib_transfer_request")
			packet:String(channelName)
			packet:Int(inboundTransfer:GetRequestId())
			packet:String(data)
		EndPacket(packet, userId)
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
