local TransactionMysql = class('LibK.TransactionMysql')
LibK.TransactionMysql = TransactionMysql

function TransactionMysql:initialize(db)
    self.waitUntilConnected = db.ConnectionPromise
    self.db = db.MySQLDB
    self.wrappedDb = db
end

function TransactionMysql:begin()
    if self.transaction then
        LibK.GLib.Error("TransactionMysql: Cannot begin transaction, begin() was already called")
    end

    self.waitUntilConnected = self.waitUntilConnected:Then(function()
        self.transaction = self.db:createTransaction()
    end)
end

function TransactionMysql:add(str)
    local def = Deferred()
    return self.waitUntilConnected:Then(function()
        if not self.transaction then
            LibK.GLib.Error("TransactionMysql: Cannot add query, begin() was not called")
        end
        local query = self.db:query(str)
        self.transaction:addQuery(query)
        return query
    end)
end

function TransactionMysql:rollback()
    return self.wrappedDb.DoQuery( "ROLLBACK" )
end

function TransactionMysql:commit()
    return self.waitUntilConnected:Then(function()
        local transactionDef = Deferred()
        function self.transaction:onSuccess()
            transactionDef:Resolve()
        end
        function self.transaction:onError(err)
            transactionDef:Reject(err or "aborted")
        end

        self.transaction:start()

        return transactionDef:Promise()
    end)
end

---

local TransactionSqlite = class("LibK.TransactionSqlite")
LibK.TransactionSqlite = TransactionSqlite

function TransactionSqlite:initialize(db)
    self.db = db
end

function TransactionSqlite:begin()
    if self.deferred then
        LibK.GLib.Error("TransactionSqlite: Cannot begin transaction, begin() was already called")
    end

    sql.Begin()
    self.deferred = Deferred()
    self.errored = false
end

function TransactionSqlite:add(sqlText)
    if not self.deferred then
        LibK.GLib.Error("TransactionSqlite: Cannot add query, begin() was not called")
    end

    -- SQLite is instantaneous, simply running the query is equal to queueing it
    self.db.Query(sqlText, callback, function(error)
        if not self.errored then
            self.errored = true
            self.deferred:Reject(sql.LastError())
        end
    end)
end

function TransactionSqlite:commit()
    if not self.deferred then
        LibK.GLib.Error("TransactionSqlite: Cannot commit transaction, begin() was not called")
    end

    sql.Commit()
    if not self.errored then
        self.deferred:Resolve()
    end

    return self.deferred:Promise()
end

function TransactionSqlite:rollback()
    self.db.Query( "ROLLBACK" )
end
