local self = {}
GAuth.Protocol.EndPoint = GAuth.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.DataChannel = "gauth_session_data"
	self.NewSessionChannel = "gauth_new_session"
	self.NotificationChannel = "gauth_notification"
end