Singleton = {}

function Singleton:included( class )
	function class.static.getInstance( )
		class.static.instance = class.static.instance or class:new( )
		return class.static.instance
	end
end