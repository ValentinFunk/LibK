LibK
====

GMOD Lua Library for fast and simple development of database backed addons. Support MySQL and SQLite with the same code.

<p align="center">
  <img src="https://github.com/Kamshak/LibK/blob/master/logo.png?raw=true" alt="LibK Banner"/>
</p>

## Database
LibK provides a few tools for database interaction:
- Abstraction through models with support for SQLite and MySQL: **No mode manual query writing - No more SQL injection**
- Possibility to set up a database connection very easily
- Gurantee that every query will be executed, automatic reconnection on database connection interruption

## Networking
- Clients can start server transactions that are wrapped as a promise
- Objects (i.e. class instances) can be sent from server to client

## Addon Loader
- Easy loading by filename
- Supports file ordering
- No need to manually include files anymore
- Load an addon after gamemode intialization
- Wait until another addon has finished loading


## Basics
This example shows a simple addon that will save player joins to the database. In any shared file: 
```lua
-- Initialize the Addon
LibK.InitializeAddon{
	addonName = "MyAddon",                  --Name of the addon
	author = "Kamshak",                     --Name of the author
	luaroot = "myaddon",                    --Folder that contains the client/shared/server structure
}

MyAddon = {}

LibK.SetupDatabase( "MyAddon", MyAddon )

-- Create a Database Model
MyAddon.PlayerJoins = class( "PlayerJoins" )
MyAddon.PlayerJoins.static.DB = "MyAddon"
MyAddon.PlayerJoins.static.model = {
	tableName = "ps2_plyjoinstreak",
	fields = {
		playerId = "int",
        	joinedTime = "createdTime" --automatically set to time this entry was created
	}
}
MyAddon.PlayerJoins:include( DatabaseModel )

-- Use It
hook.Add( "LibK_PlayerInitialSpawn", "Save Player Join", function( ply )
	local join = Pointshop2.PlayerJoins:new( )
	join.playerId = ply.kPlayerId
	join:save()
end )

```

## Addon Structure
LibK suggests a simple addon structure that seperates code and divides code into shared, server and client folders.
- addons
  - LibK
  - YourAddon
    - lua
      - autorun
        - youraddon_init.lua 
      - youraddon
        - client
        - shared
          - sh\_0\_youraddon.lua
          - sh_config.lua
        - server
          - sv_youraddon.lua 

This is purely optional, some features can only be used with this structure however.

## Setting up an addon
The file youraddon_init.lua should call LibK.InitializeAddon which automatically adds client and shared files to the lua datapack and the addon reload list. The reload list allows you to fully reload your addon using a console command. It makes sure that all dependent addons are loaded in the correct order.

Shared code is always loaded before server/client specific code.
To further specify load orders use numbers in the file names, e.g.:

- sh\_0\_loadedFirst.lua
- sh\_1\_loadedSecond.lua
- sh_doesntMatterWhenLoaded.lua

Example file content:

youraddon_init.lua:
```lua
--Example:
LibK.InitializeAddon{
	addonName = "YourAddon",                  --Name of the addon
	author = "Kamshak",                       --Name of the author
	luaroot = "youraddon",                    --Folder that contains the client/shared/server structure relative to the                                               --lua folder
}
LibK.addReloadFile( "autorun/youraddon_init.lua" ) --Path to the file so it can be reloaded using the libk_reload command
```

sh\_0\_youraddon.lua:
```lua
YourAddon = {}
```
The global addon table is created shared.


sh_config.lua:
```lua
YourAddon.Config = {}
YourAddon.Config.startHp = 100 --Example setting
```
All settings should be put in here. Everything should be commented.


sv_youraddon.lua:
```lua
LibK.SetupDatabase( "YourAddon", YourAddon )
```
The database connection is set up(see below for details)


### Setting up a database connection
Generally every addon using LibK should have a global addon table that contains all models.

To get a database connection the function LibK.SetupDatabase( pluginName, pluginTable ) should be used. pluginName a string used to identify the addon and a unique identifier. pluginTable is the global addon table that contains all models. 

```lua
--Example:
LibK.SetupDatabase( "YourAddon", YourAddon )
```

The database will connect using the LibK settings (MySQL or SQLite) and initialize all models (create tables etc.)
When the datbase has connected the function YourAddon.onDatabaseConnected will be called if it exists.

### Models
The main feature of LibK are models, these allow backend independent usage of databases.
The plugin generally follows the cakephp conventions.

A model needs to be a class that has a static DB string, which is the identifier given to LibK.SetupDatabase.
It then needs a static model table which contains info about the fields. The format is a table with field name as the keys and field type as values. An id field is automatically added to each table and does not have to be specified

Available fieldtypes are:
- string:
  Maximum 255 Characters long string
- int:
  Integer value, cannot be NULL
- optKey:
  Optional key to a different table, can be NULL
- table:
  Special field, if this is set the object's first level table is serialized and saved to the database, else only 
  class.saveFields fields are saved. This should not be used much but can be useful sometimes when the structure of an object can differ
- bool:
  True or False (0 or 1)
- player:
  Datatype to save a player reference by SteamID, difference to string is that some more magic functions work with it.
- playerUid:
  Int big enough to save a player's unique id
- classname:
  Special field, automatically saves the classname of the class. If you want to save inherited classes this can be useful
- createdTime:
  Automatically set to the time the entry was created (timestamp)
- updatedTime:
  Automatically set to the time the entry was last updated (timestamp)
- time:
  Time field (timestamp)
- text:
  Long chunk of text(=MEDIUMTEXT)

Time fields are saved as TIMESTAMP and automatically converted to a number in lua when the object is loaded.

Example model:
```lua
KMapVote.Rating = class( "KRating" )

KMapVote.Rating.static.DB = "KMapVote" --The identifier of the database as given to LibK.SetupDatabase
KMapVote.Rating.static.model = {
	tableName = "kmapvote_ratings",
	fields = {
		ownerId = "int",
		stars = "int",
		comment = "text", 
		mapname = "string"
  }
}

KMapVote.Rating:include( DatabaseModel ) --Adds the model functionality and automagic functions
```
The global plugin table is KMapVote in this case. 

To load objects you can use the created automagic functions model.findByField( value ).
You can also specify a custom WHERE query using model.getDbEntries( whereString ).
These functions return a promise that returns the found objects.
Examples:
```lua
--Find all ratings owned by player with id 5
KMapVote.Rating.findByOwnerId( 5 )
:Then( function( ratings )
    for _, rating in pairs( ratings ) do
      print( "Map Rating for map " .. rating.mapname .. ":" )
      print( "-> " .. rating.stars .. " stars" )
    end
end )

--Get all ratings:
KMapVote.Rating.getDbEntries( "WHERE 1 = 1" )
:Then( function( allRatings )
    PrintTable( allRatings )
end )
```

To create a new db entry use model:new( ) 
then model:save( ) to save it
```lua
local rating = KMapVote.Rating:new( )
rating.stars = 4
rating.ownerId = player.GetByID( 2 ).kPlayerId
rating.mapname = game.GetMap( )
rating:save( )
:Done( function( )
  print( "Saved the rating!" )
end )
:Fail( function( errid, err )
  print( "Couldn't save the rating :( errror was: ", err )
end )
```

## References
- Promises: [Introduction](http://blog.parse.com/2013/01/29/whats-so-great-about-javascript-promises/)
- Middleclass: [Wiki](https://github.com/kikito/middleclass)

## License
Copyright (c) 2016 Valentin Funk
```
The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.```
