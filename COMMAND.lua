-- MIT License

-- Copyright (c) 2019 iPad水晶

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
IKit = (function()
    local CLASS = {};
    local INTERFACES = {};

    local Interface = function(_name,_method,_super)
        if INTERFACES[_name] ~= nil then
            error("接口'".. _name .."'重复定义");
        end
        if _super ~= nil then
            if INTERFACES[_super] == nil then
                error("未找到接口'".. _super .."'");
            end
            for i = 1, #INTERFACES[_super],1 do
                _method[#_method + 1] = INTERFACES[_super][i];
            end
        end
        INTERFACES[_name] = _method;
    end

    local Class = function(_table,_name,_super)
        if CLASS[_name] ~= nil then
            error("类'".. _name .."'重复定义");
        end

        _super = _super or {}
        _super.extends = _super.extends or "Object";
        _super.implements = _super.implements or {};

        for i = 1, #_super.implements, 1 do
            for j = 1, #INTERFACES[_super.implements[i]],1 do
                if rawget(_table,INTERFACES[_super.implements[i]][j]) == nil then
                    error("未实现接口'" .. _super.implements[i] .. "'中的方法:" .. INTERFACES[_super.implements[i]][j]);
                end
            end
        end

        CLASS[_name] = {
            Table = _table,
            Super = _super.extends,
            Interface = _super.implements;
        };
    end

    local function _CALL(table,...)
        table:constructor(...);
    end

    local function _NEWINDEX(table,key,value)
        if value == nil then
            error("不可将字段设置为nil");
        end
        local temporary = table;
        if key == "type" and temporary.type ~= "nil" then
            error("type不可修改");
        end
        while table ~= nil do
            for k in pairs(table) do
                if key == k then
                    rawset(table,key,value);
                    return;
                end
            end
            table = getmetatable(table);
        end
        if temporary.type == "nil" then
            rawset(temporary,key,value);
        else
            error("没有找到字段'" .. key .. "'在'" .. temporary.type .."'内");
        end
    end

    CLASS["Object"] = {
        Table = {
            memory = {};
            type = "nil",
            __call = _CALL,
            __newindex = _NEWINDEX,
        },
        Super = "nil",
        Interface = "nil",
    }

    local function Clone(_name)
        if CLASS[_name] == nil then
            error("没有找到类'" .. _name .. "'");
        end
        local object = {};
        for key, value in pairs(CLASS[_name].Table) do
            object[key] = value;
        end
        object.__index = object;
        if CLASS[_name].Super ~= "nil" then
            object.super = Clone(CLASS[_name].Super)
            object.__newindex = object.super.__newindex;
            object.__call = object.super.__call;
            setmetatable(object,object.super);
        end
        return object;
    end

    local New = function(_name,...)
        local object = Clone(_name);
        object(...);
        object.type = _name;
        return setmetatable({},object);
    end

    local function Instanceof(_object,_name)
        if type(_object) == "table" and  type(_name) == "string" and (CLASS[_name] ~= nil or INTERFACES[_name] ~= nil) then
            if INTERFACES[_name] ~= nil then
                local type = _object.type;
                while type ~= nil do
                    if type == _name then
                        return true;
                    end
                    type = CLASS[type].Super;
                end
            end
            if INTERFACES[_name] ~= nil then
                for i = 1, INTERFACES[_name], 2 do
                    if rawget(_object,INTERFACES[_name][i]) == nil then
                        return false;
                    end
                end
                return true;
            end
        end
        return false;
    end
    local function TypeOf(value)
        if type(value) == "table" then
            if value.type ~= nil then
                return value.type;
            end
        end
        return type(value);
    end
    return{
        Interface = Interface,
        Class = Class,
        New = New,
        Instanceof = Instanceof,
        TypeOf = TypeOf
    };
end)();

(function()
    local function charSize(curByte)
        local seperate = {0, 0xc0, 0xe0, 0xf0}
        for i = #seperate, 1, -1 do
            if curByte >= seperate[i] then return i end
        end
        return 1
    end
    local String = {};

    function String:constructor(value)
        self.array = {};
        self.length = 0;
        self:insert(value);
    end

    function String:charAt(index)
        if index > 0 and index <= self.length then
            return self.array[index];
        end
        error("数组下标越界");
    end

    function String:substring(beginindex,endindex)
        local text = IKit.New("String");
        for i = beginindex, endindex, 1 do
            text:insert(self.array[i]);
        end
        return text;
    end

    function String:isEmpty()
        return self.length == 0;
    end

    function String:insert(value,pos)
        pos = pos or self.length + 1;
        if type(value) == "string" then
            local currentIndex = 1;
            while currentIndex <= #value do
                local cs = charSize(string.byte(value, currentIndex));
                if pos > self.length then
                    self.array[#self.array+1] = string.sub(value,currentIndex,currentIndex+cs-1);
                else
                    table.insert(self.array,pos,string.sub(value,currentIndex,currentIndex+cs-1));
                end
                currentIndex = currentIndex + cs;
                self.length = self.length + 1;
                pos = pos + 1;
            end
        elseif type(value) == "table" then
            if value.type == "String" then
                for i = 1, value.length, 1 do
                    if pos > self.length then
                        self.array[#self.array+1] = value.array[i];
                    else
                        table.insert(self.array,pos,value.array[i]);
                    end
                    pos = pos + 1;
                end
                self.length = self.length +  value.length;
            else
                local currentIndex = 1;
                while currentIndex <= #value do
                    local cs = charSize(value[currentIndex])
                    if pos > self.length then
                        if cs == 1 then
                            self.array[#self.array+1] = string.char(value[currentIndex]);
                        elseif cs == 2 then
                            self.array[#self.array+1] = string.char(value[currentIndex],value[currentIndex+1]);
                        elseif cs == 3 then
                            self.array[#self.array+1] = string.char(value[currentIndex],value[currentIndex+1],value[currentIndex+2]);
                        elseif cs == 4 then
                            self.array[#self.array+1] = string.char(value[currentIndex],value[currentIndex+1],value[currentIndex+2],value[currentIndex+3]);
                        end
                    else
                        if cs == 1 then
                            table.insert(self.array,pos,string.char(value[currentIndex]));
                        elseif cs == 2 then
                            table.insert(self.array,pos,string.char(value[currentIndex],value[currentIndex+1]));
                        elseif cs == 3 then
                            table.insert(self.array,pos,string.char(value[currentIndex],value[currentIndex+1],value[currentIndex+2]));
                        elseif cs == 4 then
                            table.insert(self.array,pos,string.char(value[currentIndex],value[currentIndex+1],value[currentIndex+2],value[currentIndex+3]));
                        end
                    end
                    currentIndex = currentIndex+cs;
                    self.length = self.length + 1;
                    pos = pos + 1;
                end
            end
        end
    end

    function String:remove(pos)
        if pos > 0 or pos <= self.length then
            table.remove(self.array,pos);
            self.length = self.length - 1;
        else
            error("数组下标越界");
        end
    end

    function String:clean()
        self.array = {};
        self.length = 0;
    end

    function String:toBytes()
        local bytes = {};
        for i = 1, self.length, 1 do
            for j = 1, #self.array[i], 1 do
                table.insert(bytes,string.byte(self.array[i],j));
            end
        end
        return bytes;
    end
    
    function String:toNumber()
        tonumber(self:toString());
    end

    function String:toString()
        return table.concat(self.array);
    end

    function String:__len()
        return self.length;
    end

    function String:__eq(value)
        return self.length == value.length and function()
            for i = 1, self.length, 1 do
                if self.array[i] ~= value.array[i] then
                    return false;
                end
            end
            return true;
        end
    end

    function String:__add(value)
        self:insert(value);
        return self;
    end

    function String:__concat(value)
        local str1 = IKit.New("String",self);
        str1:insert(value);
        return str1;
    end
                
    IKit.Class(String,"String");
end)();

(function()
    local Event = {};

    function Event:constructor()
        self.array = {};
        self.id = 1;
    end

    function Event:__add(name)
        if not self.array[name] then
            self.array[name] = {};
            return self;
        end
        error("事件:''" ..name.. "'已经存在,请勿重复添加");
    end

    function Event:__sub(name)
        if self.array[name] then
            self.array[name] = nil;
            return self;
        end
        error("事件:'" ..name.."'不存在");
    end

    function Event:addEventListener(name,event)
        if self.array[name] == nil then
            error("未找到事件'" .. name .. "'");
        end
        if type(event) == "function" then
            self.array[name][#self.array[name] + 1] = {self.id,event};
            self.id = self.id + 1;
            return self.id - 1;
        else
            error("它应该是一个函数");
        end
    end

    function Event:detachEventListener(name,id)
        if self.array[name] == nil then
            error("未找到'" .. name .. "'");
        end
        for i = 1, #self.array[name],1 do
            if self.array[name][i][1] == id then
                table.remove(self.array[name],i);
                return;
            end
        end
        error("未找到'" .. id .. "'在Event[" .. name .."]内");
    end

    function Event:forEach(name,...)
        for i = #self.array[name],1,-1 do
            self.array[name][i][2](...);
        end
    end

    IKit.Class(Event,"Event");
end)();

(function()
    local Timer = {};

    function Timer:constructor()
        self.id = 1;
        self.task = {};
        Event:addEventListener("OnUpdate",function(time)
            self:OnUpdate(time);
        end);
    end

    function Timer:OnUpdate(time)
        for key, value in pairs(self.task) do
            if value.time < time then
                local b,m = pcall(value.func);
                if not b then
                    self.task[key] = nil;
                    print("Timer:ID为:[" .. key .. "]的函数发生了异常");
                    print(m);
                elseif value.period == nil then
                    self.task[key] = nil;
                else
                    value.time = time + value.period;
                end
            end
        end
    end

    function Timer:schedule(fun,delay,period)
        if Game ~= nil then
            self.task[self.id] = {func = fun,time = Game.GetTime() + delay,period = period};
        end
        if UI ~= nil then
            self.task[self.id] = {func = fun,time = UI.GetTime() + delay,period = period};
        end
        self.id = self.id + 1;
        return self.id - 1;
    end

    function Timer:cancel(id)
        self.task[id] = nil;
    end
    
    function Timer:purge()
        self.task = {}
    end

    IKit.Class(Timer,"Timer");
end)();

local Group  = {
    default = 0,
    administrator = 1,
}

(function()
    local ServerCommand = {};
    
    function ServerCommand:constructor()

        self.sendbuffer = {};
        self.receivbBuffer = {};
        self.methods = {};

        self.message = Game.SyncValue:Create("Message");
        local OnPlayerSignalId = 0;
        local OnUpdateId = 0;
        function self:connection()
            OnUpdateId = Event:addEventListener("OnUpdate",function()
                self:OnUpdate();
            end);
            OnPlayerSignalId = Event:addEventListener("OnPlayerSignal",function(player,signal)
                self:OnPlayerSignal(player,signal);
            end);

            Event:addEventListener("OnPlayerConnect",function(player)
                player.user.group = Group.default;
            end);
        end
        function self:disconnect()
            Event:detachEventListener("OnPlayerSignal",OnPlayerSignalId);
            Event:detachEventListener("OnUpdate",OnUpdateId);
        end
        self:connection();
    end

    function ServerCommand:OnUpdate()
        local k = 0;
        while #self.sendbuffer > 0 do
            while #self.sendbuffer[1][2] > 0 do
                self.sendbuffer[1][1]:Signal(self.sendbuffer[1][2][1]);
                table.remove(self.sendbuffer[1][2],1);
                k = k + 1;
                if k == 256 then
                    return;
                end
            end
            if #self.sendbuffer[1][2] == 0 then
                table.remove(self.sendbuffer,1);
            end
        end
    end

    function ServerCommand:OnPlayerSignal(player,signal)
        if signal == 4 then
            local command = IKit.New("String",self.receivbBuffer[player.name]);
            local args = {IKit.New("String")};
            for i = 1, command.length, 1 do
                if command:charAt(i) == ' ' then
                    if args[#args].length > 0 then
                        table.insert(args,IKit.New("String"));
                    end
                else
                    args[#args]:insert(command:charAt(i));
                end
            end
            if args[#args].length == 0 then
                table.remove(args,#args);
            end
            self:execute(player,args);
            self.receivbBuffer[player.name] = {};
        else
            if self.receivbBuffer[player.name] == nil then
                self.receivbBuffer[player.name] = {};
            end
            table.insert(self.receivbBuffer[player.name],signal);
        end
    end

    function ServerCommand:register(name,group,fun)
        self.methods[name] ={group,fun};
    end

    function ServerCommand:sendMessage(message,player)
        if player == nil then
            self.message.value = message;
        else
            local message = IKit.New("String",message);
            local bytes = message:toBytes();
            table.insert(bytes,4);
            table.insert(self.sendbuffer,{player,bytes});
        end
    end


    function ServerCommand:execute(player,args)
        local name = args[1];
        table.remove(args,1);
        local b,m = pcall(function()
            if not self.methods[name:toString()] then
                print("没有指令:/"..name:toString());
                return;
            end
            if self.methods[name:toString()][1] < player.user.group then
                self.methods[name:toString()][2](player,args);
            else
                print("权限不足:/"..name:toString());
            end
        end);
        if not b then
            print("在执行'" .. name:toString() .. "'命令时发生异常");
            print(m);
        end
    end
    IKit.Class(ServerCommand,"ServerCommand");
end)();

(function()
    local  ClientCommand = {};
    
    function ClientCommand:constructor()

        self.sendbuffer = {};
        self.receivbBuffer = {};
        self.methods = {};

        self.message = UI.SyncValue:Create("Message");
        local OnSignalId = 0;
        local OnUpdateId = 0;
        local OnChatId = 0;
        function self:connection()
            OnSignalId = Event:addEventListener("OnSignal",function(signal)
                self:OnSignal(signal);
            end);
            OnUpdateId = Event:addEventListener("OnUpdate",function()
                self:OnUpdate();
            end);
            OnChatId = Event:addEventListener("OnChat",function(text)
                self:OnChat(text);
            end);
        end
        function self:disconnect()
            Event:detachEventListener("OnSignal",OnSignalId);
            Event:detachEventListener("OnUpdate",OnUpdateId);
            Event:detachEventListener("OnUpdate",OnChatId);
        end
        function self.message.OnSync(table)
            print(self.message.value)
            self:execute({IKit.New("String",self.message.value)});
        end
        self:connection();
    end

    function ClientCommand:OnUpdate()
        local i = 0;
        while #self.sendbuffer > 0 do
            UI.Signal(self.sendbuffer[1]);
            table.remove(self.sendbuffer,1);
            i = i + 1;
            if i == 6 then
                return;
            end
        end
    end

    function ClientCommand:OnSignal(signal)
        if signal == 4 then
            local command = IKit.New("String",self.receivbBuffer);
            local args = {IKit.New("String")};
            for i = 1, command.length, 1 do
                if command:charAt(i) == ' ' then
                    if args[#args].length > 0 then
                        table.insert(args,IKit.New("String"));
                    end
                else
                    args[#args]:insert(command:charAt(i));
                end
            end
            if args[#args].length == 0 then
                table.remove(args,#args);
            end
            self:execute(args);
            self.receivbBuffer = {};
        else
            table.insert(self.receivbBuffer,signal);
        end
    end

    function ClientCommand:OnChat(text)
        print(text);
        if string.sub(text,1,1) == '/' and #text > 1 then
            self:sendMessage(string.sub(text,2,#text));
        end
    end

    function ClientCommand:register(name,fun)
        self.methods[name] = fun;
    end

    function ClientCommand:sendMessage(message)
        local message = IKit.New("String",message)
        local bytes = message:toBytes();
        for i = 1, #bytes, 1 do
            table.insert(self.sendbuffer,bytes[i]);
        end
        table.insert(self.sendbuffer,4);
    end

    function ClientCommand:execute(args)
        local name = args[1];
        table.remove(args,1);
        if pcall(self.methods[name:toString()],args) == false then
            print("在执行'" .. name:toString() .. "'命令时发生异常");
        end
    end

    IKit.Class(ClientCommand,"ClientCommand");
end)();

Event = IKit.New("Event");

if Game~=nil then
    Event = Event
    + "OnPlayerConnect"
    + "OnPlayerDisconnect"
    + "OnRoundStart"
    + "OnRoundStartFinished"
    + "OnPlayerSpawn"
    + "OnPlayerJoiningSpawn"
    + "OnPlayerKilled"
    + "OnKilled"
    + "OnPlayerSignal"
    + "OnUpdate"
    + "OnPlayerAttack"
    + "OnTakeDamage"
    + "CanBuyWeapon"
    + "CanHaveWeaponInHand"
    + "OnGetWeapon"
    + "OnReload"
    + "OnReloadFinished"
    + "OnSwitchWeapon"
    + "PostFireWeapon"
    + "OnGameSave"
    + "OnLoadGameSave"
    + "OnClearGameSave";

    function Game.Rule:OnPlayerConnect (player)
        Event:forEach("OnPlayerConnect",player);
    end
    
    function Game.Rule:OnPlayerDisconnect (player)
        Event:forEach("OnPlayerDisconnect",player);
    end
    
    function Game.Rule:OnRoundStart ()
        Event:forEach("OnRoundStart");
    end
    
    function Game.Rule:OnRoundStartFinished ()
        Event:forEach("OnRoundStartFinished");
    end
    
    function Game.Rule:OnPlayerSpawn (player)
        Event:forEach("OnPlayerSpawn",player);
    end
    
    function Game.Rule:OnPlayerJoiningSpawn (player)
        Event:forEach("OnPlayerJoiningSpawn",player);
    end
    
    function Game.Rule:OnPlayerKilled (victim, killer, weapontype, hitbox)
        Event:forEach("OnPlayerKilled",victim, killer, weapontype, hitbox);
    end
    
    function Game.Rule:OnKilled (victim, killer)
        Event:forEach("OnKilled",victim,killer);
    end
    
    function Game.Rule:OnPlayerSignal (player,signal)
        Event:forEach("OnPlayerSignal",player,signal);
    end
    
    function Game.Rule:OnUpdate (time)
        Event:forEach("OnUpdate",time);
    end
    
    function Game.Rule:OnPlayerAttack (victim, attacker, damage, weapontype, hitbox)
        Event:forEach("OnPlayerAttack",victim, attacker, damage, weapontype, hitbox);
    end
    
    function Game.Rule:OnTakeDamage (victim, attacker, damage, weapontype, hitbox)	
        Event:forEach("OnTakeDamage",victim, attacker, damage, weapontype, hitbox);
    end
    
    function Game.Rule:CanBuyWeapon (player, weaponid)
        Event:forEach("CanBuyWeapon",player,weaponid);
    end
    
    function Game.Rule:CanHaveWeaponInHand (player, weaponid, weapon)
        Event:forEach("CanHaveWeaponInHand",player, weaponid, weapon);
    end
    
    function Game.Rule:OnGetWeapon (player, weaponid, weapon)
        Event:forEach("OnGetWeapon",player, weaponid, weapon);
    end
    
    function Game.Rule:OnReload (player, weapon, time)
        Event:forEach("OnPlayerConnect",player, weapon, time);
    end
    
    function Game.Rule:OnReloadFinished (player, weapon)
        Event:forEach("OnPlayerConnect",player, weapon);
    end
    
    function Game.Rule:OnSwitchWeapon (player)
        Event:forEach("OnPlayerConnect",player);
    end
    
    function Game.Rule:PostFireWeapon (player, weapon, time)
        Event:forEach("OnPlayerConnect",player, weapon, time);
    end
    
    function Game.Rule:OnGameSave (player)
        Event:forEach("OnPlayerConnect",player);
    end
    
    function Game.Rule:OnLoadGameSave (player)
        Event:forEach("OnPlayerConnect",player);
    end
    
    function Game.Rule:OnClearGameSave (player)
        Event:forEach("OnPlayerConnect",player);
    end
end

if UI~=nil then
    Event = Event
    + "OnRoundStart"
    + "OnSpawn"
    + "OnKilled"
    + "OnInput"
    + "OnUpdate"
    + "OnChat"
    + "OnSignal"
    + "OnKeyDown"
    + "OnKeyUp"
    
    function UI.Event:OnRoundStart()
        Event:forEach("OnRoundStart");
    end

    function UI.Event:OnSpawn()
        Event:forEach("OnSpawn");
    end

    function UI.Event:OnKilled()
        Event:forEach("OnKilled");
    end

    function UI.Event:OnInput (inputs)
        Event:forEach("OnInput",inputs);
    end

    function UI.Event:OnUpdate(time)
        Event:forEach("OnUpdate",time);
    end

    function UI.Event:OnChat (text)
        Event:forEach("OnChat",text);
    end

    function UI.Event:OnSignal(signal)
        Event:forEach("OnSignal",signal);
    end

    function UI.Event:OnKeyDown(inputs)
        Event:forEach("OnKeyDown",inputs);
    end

    function UI.Event:OnKeyUp (inputs)
        Event:forEach("OnKeyUp",inputs);
    end
end

Timer = IKit.New("Timer");

if Game ~= nil then

    Command = IKit.New("ServerCommand");

    Command:register("自杀",Group.default,function(player,args)
        player:Kill();
    end)
    
    Command:register("冻结",Group.administrator,function(player,args)
        Command:sendMessage("stop");
    end)

end

if UI ~= nil then
    Command = IKit.New("ClientCommand");

    Command:register("stop",function(args)
        UI.StopPlayerControl(true);
    end);
end