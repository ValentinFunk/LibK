local self = {}
GAuth.Protocol.InitialSyncRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("InitialSyncRequest", GAuth.Protocol.InitialSyncRequest)

function self:ctor ()
end

function self:GenerateInitialPacket (outBuffer)
end

function self:HandleInitialPacket (inBuffer)
	GAuth.GroupTreeSender:SendNode (self:GetRemoteEndPoint ():GetRemoteId (), GAuth.Groups)
end