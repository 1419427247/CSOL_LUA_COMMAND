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
        return tonumber(self:toString());
    end

    function String:toString()
        return table.concat(self.array);
    end

    function String:equals(value)
        local t = IKit.TypeOf(value);
        if t == "String" then
            return self == value;
        elseif t == "string" then
            return self:toString() == value;
        end
    end

    function String:__len()
        return self.length;
    end

    function String:__eq(value)
        if self.length ~= value.length then
            return false;
        end
        for i = 1, self.length, 1 do
            if self.array[i] ~= value.array[i] then
                return false;
            end
        end
        return true;
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

Timer = IKit.New("Timer");

(function()
    local Player = {};

    function Player:constructor()
        self.map = {};

        Event:addEventListener("OnPlayerConnect",function(player)
            self.map[player.name] = player;
            player.user.memory = {};
        end);

        Event:addEventListener("OnPlayerDisconnect",function(player)
            self.map[player.name] = nil;
        end);
    end

    function Player:killAllPlayers()
        for _,value in pairs(self.map) do
            value:Kill();
        end
    end

    function Player:showBuymenu()
        for _,value in pairs(self.map) do
            value:ShowBuymenu();
        end
    end

    function Player:getPlayerByIndex(index)
        for key, value in pairs(self.map) do
            if value.index == index then
                return value;
            end
        end
    end

    function Player:getPlayerByName(name,enable)
        if enable then
            for key, value in pairs(self.map) do
                if(string.find(key,name)) then
                    return value;
                end
            end
        else
            return self.map[name];
        end
    end

    IKit.Class(Player,"Player");
end)();

if Game then
    Player = IKit.New("Player");
end

local Group  = {
    none = -1,
    default = 0,
    administrator = 1,
};

(function()
    local ServerCommand = {};
    
    function ServerCommand:constructor(config)
        print()
        self.safeMode = config["安全模式"];
        self.maximumNumberOfBytes = config["每帧最大发送字节数"];
        self.spacer = config["间隔符"];
        self.useGroup = config["启用用户组"];
        self.DefaultUserGroup = config["默认用户组"];

        self.sendBuffer = {};
        self.receivbBuffer = {};
        self.methods = {};
        
        self.message = Game.SyncValue:Create("Message");
        

        if self.useGroup then
            Event:addEventListener("OnPlayerConnect",function(player)
                player.user.group = self.DefaultUserGroup;
            end);
        end

        local OnPlayerSignalId = 0;
        local OnUpdateId = 0;
        function self:connection()
            OnUpdateId = Event:addEventListener("OnUpdate",function()
                self:OnUpdate();
            end);
            OnPlayerSignalId = Event:addEventListener("OnPlayerSignal",function(player,signal)
                self:OnPlayerSignal(player,signal);
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
        while #self.sendBuffer > 0 do
            while #self.sendBuffer[1][2] > 0 do
                self.sendBuffer[1][1]:Signal(self.sendBuffer[1][2][1]);
                table.remove(self.sendBuffer[1][2],1);
                k = k + 1;
                if k == self.maximumNumberOfBytes then
                    return;
                end
            end
            if #self.sendBuffer[1][2] == 0 then
                table.remove(self.sendBuffer,1);
            end
        end
    end

    function ServerCommand:OnPlayerSignal(player,signal)
        if signal == 4 then
            local command = IKit.New("String",self.receivbBuffer[player.name]);
            local args = {IKit.New("String")};
            for i = 1, command.length, 1 do
                if command:charAt(i) == self.spacer then
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
            table.insert(self.sendBuffer,{player,bytes});
        end
    end


    function ServerCommand:execute(player,args)
        local name = args[1];
        table.remove(args,1);

        if not self.methods[name:toString()] then
            print("没有指令:"..name:toString());
            return;
        end

        if self.useGroup then
            if self.methods[name:toString()][1] > player.user.group then
                print("权限不足:"..name:toString());
                return;
            end
        end
        
        for i = 1,#args do
            if args[i]:charAt(1) == "$" then
                args[i] = player.user.memory[args[i]:substring(2,args[i].length):toString()];
            end
        end
        if self.safeMode then
            local a,b = pcall(self.methods[name:toString()][2],player,args);
            if not a then
                print("在执行'" .. name:toString() .. "'命令时发生异常");
                print(b);
            end
        else
            self.methods[name:toString()][2](player,args);
        end 
              
    end
    IKit.Class(ServerCommand,"ServerCommand");
end)();

(function()
    local  ClientCommand = {};
    
    function ClientCommand:constructor(config)

        self.safeMode = config["安全模式"];
        self.maximumNumberOfBytes = config["每帧最大发送字节数"];
        self.startCharacter = config["起始符"];
        self.spacer = config["间隔符"];


        self.sendBuffer = {};
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
            self:execute({IKit.New("String",self.message.value)});
        end
        self:connection();
    end

    function ClientCommand:OnUpdate()
        local i = 0;
        while #self.sendBuffer > 0 do
            UI.Signal(self.sendBuffer[1]);
            table.remove(self.sendBuffer,1);
            i = i + 1;
            if i == self.maximumNumberOfBytes then
                return;
            end
        end
    end

    function ClientCommand:OnSignal(signal)
        if signal == 4 then
            local command = IKit.New("String",self.receivbBuffer);
            local args = {IKit.New("String")};
            for i = 1, command.length, 1 do
                if command:charAt(i) == self.spacer then
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
        if string.sub(text,1,#self.startCharacter) == self.startCharacter and #text > #self.startCharacter then
            self:sendMessage(string.sub(text,#self.startCharacter + 1,#text));
        end
    end

    function ClientCommand:register(name,fun)
        self.methods[name] = fun;
    end

    function ClientCommand:sendMessage(message)
        local message = IKit.New("String",message)
        local bytes = message:toBytes();
        for i = 1, #bytes, 1 do
            table.insert(self.sendBuffer,bytes[i]);
        end
        table.insert(self.sendBuffer,4);
    end

    function ClientCommand:execute(args)
        local name = args[1];
        table.remove(args,1);

        if self.safeMode then
            if pcall(self.methods[name:toString()],args) == false then
                print("在执行'" .. name:toString() .. "'命令时发生异常");
            end
        else
            self.methods[name:toString()](args);
        end
    end
    IKit.Class(ClientCommand,"ClientCommand");
end)();

if Game ~= nil then



    Command = IKit.New("ServerCommand",{
        ["安全模式"] = false,
        ["每帧最大发送字节数"] = 64,
        ["间隔符"] = " ",
        ["启用用户组"] = false,
        ["默认用户组"] = Group.default,
    });

    --/! [$VariableName(string) or Expression]
    Command:register("!",Group.administrator,function(player,args)
        SELF = player;
        if #args == 1 then
            if(IKit.TypeOf(args[1]) == "String") then
                load(args[1]:toString())();
            else
                load(args[1])();
            end
        else
            local str = IKit.New("String");
            for i = 1,#args do
                str:insert(args[i]);
                str:insert(" ");
            end
            load(str:toString())();
        end
    end);

    --/$ [$VariableName] [Expression]
    Command:register("$",Group.default,function(player,args)
        if #args == 2 then
            if IKit.TypeOf(args[2]) == "String" then
                args[2]:insert("return ",1);
                player.user.memory[args[1]:toString()] = load(args[2]:toString())();
            else
                player.user.memory[args[1]:toString()] = args[2];
            end
        elseif #args > 2 then
            local str = IKit.New("String","return ");
            for i = 2,#args do
                str:insert(args[i]);
                str:insert(" ");
            end
            player.user.memory[args[1]:toString()] = load(str:toString())();
        end
        print(player.name .. ":" .. args[1]:toString());
        print(player.user.memory[args[1]:toString()]);
        print("--------------------");
    end);

    --/$pos [VariableName]
    Command:register("$pos",Group.default,function(player,args)
        player.user.memory[args[1]:toString()] = {
            x = player.position.x,
            y = player.position.y,
            z = player.position.z,
        };
        print(player.name .. ":" .. args[1]:toString());
        print("x:" .. player.position.x);
        print("y:" .. player.position.y);
        print("z:" .. player.position.z);
        print("--------------------");
    end);

    --/$playerpos [VariableName] [Name]
    Command:register("$playerpos",Group.default,function(player,args)
        local p = Player:getPlayerByName(args[2]:toString(),true);
        if p == nil then
            print("没有找到该玩家");
            return;
        end
        player.user.memory[args[1]:toString()] = {
            x = p.position.x,
            y = p.position.y,
            z = p.position.z,
        };
        print(player.name .. ":" .. args[1]:toString());
        print("x:" .. player.position.x);
        print("y:" .. player.position.y);
        print("z:" .. player.position.z);
        print("--------------------");
    end);

    --/$player [VariableName] [Name]
    Command:register("$player",Group.default,function(player,args)
        player.user.memory[args[1]:toString()] = Player:getPlayerByName(args[2]:toString(),true);
        print(player.name .. ":" .. args[1]:toString());
        print("姓名:" .. player.user.memory[args[1]:toString()].name);
        print("序号:" .. player.user.memory[args[1]:toString()].index);
        print("--------------------");
    end);

    --/group [$VariableName(userdata) or Name] [Group]
    Command:register("group",Group.administrator,function(player,args)
        if #args == 1 then
            player.user.group = Group[args[1]];
        elseif #args == 2 then
            if IKit.TypeOf(args[1]) == "String" then
                local p = Player:getPlayerByName(args[1]:toString(),true);
                if p == nil then
                    print("没有找到玩家");
                    return;
                end
                p.user.group = Group[args[1]];
            else
                args[1].user.group = Group[args[1]];
            end
        end
    end);

    --/tp [$VariableName(userdata) or Name]
    Command:register("tp",Group.default,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            player.position = Player:getPlayerByName(args[1]:toString(),true).position;
        else
            player.position = args[1].position;
        end
    end);

    --/tppos [$VariableName(table)]
    --/tppos [X] [Y] [Z]
    Command:register("tppos",Group.default,function(player,args)
        if #args == 1 then
            if IKit.TypeOf(args[1]) == "table" then
                player.position = args[1];
            end
        elseif #args == 3 then
            player.position = {
                x = args[1]:toNumber(),
                y = args[2]:toNumber(),
                z = args[3]:toNumber(),
            };
        end
    end);

    --/sethome
    --/sethome [$VariableName(table)]
    --/sethome [X] [Y] [Z]
    Command:register("sethome",Group.default,function(player,args)
        if #args == 0 then
            player.user.home = {
                x = player.position.x,
                y = player.position.y,
                z = player.position.z,
            };
        elseif #args == 1 then
            player.user.home = args[1];
        elseif #args == 3 then
            player.user.home = {
                x = args[1]:toNumber();
                y = args[2]:toNumber();
                z = args[3]:toNumber();
            };
        end
    end);

    --/home
    Command:register("home",Group.default,function(player,args)
        player.user.home = player.user.home or player.position;
        player.position = player.user.home;
    end);

    --/setplayer [$VariableName(userdata) or Name] [Key] [$VariableName or Value]
    Command:register("setplayer",Group.default,function(player,args)
        local p;
        if IKit.TypeOf(args[1]) == "String" then
            p = Player:getPlayerByName(args[1]:toString(),true);
            if p == nil then
                print("没有找到玩家");
                return;
            end
        else
            p = args[1];
        end

        if p[args[2]:toString()] == nil then
            print("没有属性:" .. args[2]:toString());
            return;
        end

        if IKit.TypeOf(args[3]) == "String" then
            p[args[2]:toString()] = args[3]:toNumber();
        else
            p[args[2]:toString()] = args[3];
        end
    end);

    --/kill
    --/kill [* or Name or $VariableName(userdata)]
    Command:register("kill",Group.administrator,function(player,args)
        if #args == 0 then
            player:Kill();
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                if args[1]:equals("*") then
                    Player:killAllPlayers();
                else
                    local p = Player:getPlayerByName(args[1]:toString(),true);
                    if p == nil then
                        print("没有找到玩家");
                        return;
                    end
                    p:Kill();
                end
            else
                args[1]:Kill();
            end
        end
    end);

    --/freeze
    --/freeze [* or Name or $VariableName(userdata)]
    Command:register("freeze",Group.administrator,function(player,args)
        if #args == 0 then
            Command:sendMessage("freeze",player);
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                if args[1]:equals("*") then
                    Command:sendMessage("freeze");
                else
                    local p = Player:getPlayerByName(args[1]:toString(),true);
                    if p == nil then
                        print("没有找到玩家");
                        return;
                    end
                    Command:sendMessage("freeze",p);
                end
            else
                Command:sendMessage("freeze",args[1]);
            end
        end
    end);

    --/unfreeze
    --/unfreeze [* or Name or $VariableName(userdata)]
    Command:register("unfreeze",Group.administrator,function(player,args)
        if #args == 0 then
            Command:sendMessage("unfreeze",player);
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                if args[1]:equals("*") then
                    Command:sendMessage("unfreeze");
                else
                    local p = Player:getPlayerByName(args[1]:toString(),true);
                    if p == nil then
                        print("没有找到玩家");
                        return;
                    end
                    Command:sendMessage("unfreeze",p);
                end
            else
                Command:sendMessage("unfreeze",args[1]);
            end
        end
    end);

    Command:register("removeweapon",Group.administrator,function(player,args)
        player:RemoveWeapon();
    end);

    --/setview
    --/setview [$VariableName(userdata) or Name]
    --/setview [MinDist] [MaxDist]
    --/setview [$VariableName(userdata) or Name] [MinDist] [MaxDist]
    Command:register("setview",Group.administrator,function(player,args)
        if #args == 0 then
            player:SetFirstPersonView();
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                local p = Player:getPlayerByName(args[1]:toString(),true);
                if p == nil then
                    print("没有找到玩家");
                    return;
                end
                p:SetFirstPersonView();
            else
                args[1]:SetFirstPersonView();
            end
        elseif #args == 2 then
            player:SetThirdPersonView (args[1]:toNumber(),args[2]:toNumber());
        elseif #args == 3 then
            if IKit.TypeOf(args[1]) == "String" then
                local p = Player:getPlayerByName(args[1]:toString(),true);
                if p == nil then
                    print("没有找到玩家");
                    return;
                end
                p:SetThirdPersonView (args[2]:toNumber(),args[3]:toNumber());
            else
                args[1]:SetThirdPersonView (args[2]:toNumber(),args[3]:toNumber());
            end
        end
    end);

    --/showbuymenu
    --/showbuymenu [$VariableName(userdata) or Name]
    Command:register("showbuymenu",Group.administrator,function(player,args)
        if #args == 0 then
            player:ShowBuymenu();
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                if args[1]:equals("*") then
                    Player:showBuymenu();
                else
                    local p = Player:getPlayerByName(args[1]:toString(),true);
                    if p == nil then
                        print("没有找到玩家");
                        return;
                    end
                    p:ShowBuymenu();
                end
            else
                args[1]:ShowBuymenu();
            end
        end
    end);

    --/respawn [$VariableName(userdata) or Name]
    Command:register("respawn",Group.administrator,function(player,args)
        if #args == 0 then
            player:Respawn();
        elseif #args == 1 then
            if IKit.TypeOf(args[1]) == "String" then
                if args[1]:equals("*") then
                    Game.Rule:Respawn();
                else
                    local p = Player:getPlayerByName(args[1]:toString(),true);
                    if p == nil then
                        print("没有找到玩家");
                        return;
                    end
                    p:Respawn();
                end
            else
                args[1]:Respawn();
            end
        end
    end);

    --/respawn [$VariableName(boolean) or true or false]
    Command:register("respawnable",Group.administrator,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            if args[1]:equals("true") then
                Game.Rule.respawnable = true;
            elseif args[1]:equals("false") then
                Game.Rule.respawnable = false;
            end
        else
            Game.Rule.respawnable = args[1];
        end
    end);

    --/respawntime [$VariableName(number) or time]
    Command:register("respawntime",Group.administrator,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            Game.Rule.respawnTime = args[1]:toNumber();
        else
            Game.Rule.respawnTime = args[1];
        end
    end);

    --/respawn [$VariableName(boolean) or true or false]
    Command:register("enemyfire",Group.administrator,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            if args[1]:equals("true") then
                Game.Rule.enemyfire = true;
            elseif args[1]:equals("false") then
                Game.Rule.enemyfire = false;
            end
        else
            Game.Rule.enemyfire = args[1];
        end
    end);

    --/friendlyfire [$VariableName(boolean) or true or false]
    Command:register("friendlyfire",Group.administrator,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            if args[1]:equals("true") then
                Game.Rule.friendlyfire = true;
            elseif args[1]:equals("false") then
                Game.Rule.friendlyfire = false;
            end
        else
            Game.Rule.friendlyfire = args[1];
        end
    end);

    --/breakable [$VariableName(boolean) or true or false]
    Command:register("breakable",Group.administrator,function(player,args)
        if IKit.TypeOf(args[1]) == "String" then
            if args[1]:equals("true") then
                Game.Rule.breakable = true;
            elseif args[1]:equals("false") then
                Game.Rule.breakable = false;
            end
        else
            Game.Rule.breakable = args[1];
        end
    end);

    --/rendercolor [$VariableName(table)]
    --/rendercolor [$VariableName(table) or Name] [$VariableName(table)]
    --/rendercolor [Red] [Green] [Blue]
    --/rendercolor [$VariableName(table) or Name] [Red] [Green] [Blue]
    Command:register("rendercolor",Group.administrator,function(player,args)
        if #args == 1 then
            player:SetRenderColor(args[1]);
        elseif #args == 2 then
            if IKit.TypeOf(args[1]) == "String" then
                local p = Player:getPlayerByName(args[1]:toString(),true);
                if p == nil then
                    print("没有找到玩家");
                    return;
                end
                p:SetRenderColor(args[2]);
            else
                args[1]:SetRenderColor(args[2]);
            end
        elseif #args == 3 then
            player:SetRenderColor({r = args[1]:toNumber(),g = args[2]:toNumber(),b = args[3]:toNumber()});
        elseif #args == 4 then
            if IKit.TypeOf(args[1]) == "String" then
                local p = Player:getPlayerByName(args[1]:toString(),true);
                if p == nil then
                    print("没有找到玩家");
                    return;
                end
                p:SetRenderColor({r = args[2]:toNumber(),g = args[3]:toNumber(),b = args[4]:toNumber()});
            else
                args[1]:SetRenderColor({r = args[2]:toNumber(),g = args[3]:toNumber(),b = args[4]:toNumber()});
            end
        end
    end);

    Command:register("setrenderfx",Group.administrator,function(player,args)
        player:SetRenderFX(Game.RENDERFX.GLOWSHELL);
    end);
end

if UI ~= nil then
    Command = IKit.New("ClientCommand",{
        ["安全模式"] = true,
        ["每帧最大发送字节数"] = 4,
        ["起始符"] = "/",
        ["间隔符"] = " ",
    });

    Command:register("freeze",function(args)
        UI.StopPlayerControl(true);
    end);

    Command:register("unfreeze",function(args)
        UI.StopPlayerControl(false);
    end);


end
