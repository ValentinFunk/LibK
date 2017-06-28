LibK.Player = class( "KPlayer" )
LibK.Player.static.DB = "LibK"

LibK.Player.static.model = {
	tableName = "libk_player",
	fields = {
		--Why save 3 different ids? Because Darkrp and the such all like to
		--use something different, save all for simplicity, even if it violates
		--db theory.
		name = "string",
		uid = "playerUid",
		steam64 = "playerUid",
		player = "player",
		created_at = "createdTime",
		updated_at = "updatedTime"
	}
}

LibK.Player:include( DatabaseModel )

function LibK.Player.static.findPlayers( subject, attribute, limit )
	if not LibK.Player.model.fields[attribute] then
		return Promise.Reject( 1, "Invalid attribute " .. attribute )
	end

	subject = "%%" .. subject .. "%%"
	subject = DATABASES[LibK.Player.DB].SQLStr( subject )
	
	limit = limit or 10

	return LibK.Player.getDbEntries( Format( 'WHERE `%s` LIKE %s LIMIT %i', attribute, subject, limit ) )
end