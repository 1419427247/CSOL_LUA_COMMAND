


string.charSize = function (str, index)
    local curByte = string.byte(str, index)
    local seperate = {0, 0xc0, 0xe0, 0xf0}
        for i = #seperate, 1, -1 do
            if curByte >= seperate[i] then return i end
        end
        return 1
end

string.len = function(str)
    local len = 0;
    local currentIndex = 1;
    while currentIndex <= #str do
        local cs = string.charSize(str, currentIndex);
        currentIndex = currentIndex + cs;
        len = len +1;
    end
    return len;
end

string.forEach = function(str,fun)
    local currentIndex = 1;
    while currentIndex <= #str do
        local cs = string.charSize(str, currentIndex);
        fun(string.sub(str,currentIndex,currentIndex+cs-1));
        currentIndex=currentIndex+cs;
    end
end

string.charAt = function()
    
end

string.bytesToString = function(bytes)
    local str = {};
    local cs;
    local seperate = {0, 0xc0, 0xe0, 0xf0}
    local currentIndex = 1
    while currentIndex <= #bytes do
        for i = #seperate, 1, -1 do
            cs = 1;
            if bytes[currentIndex] >= seperate[i] then 
                cs = i ;
                break;
            end
        end
        if cs == 1 then
            table.insert(str,string.char(bytes[currentIndex]));
        elseif cs == 2 then
            table.insert(str,string.char(bytes[currentIndex],bytes[currentIndex+1]));
        elseif cs == 3 then
            table.insert(str,string.char(bytes[currentIndex],bytes[currentIndex+1],bytes[currentIndex+2]));
        elseif cs == 4 then
            table.insert(str,string.char(bytes[currentIndex],bytes[currentIndex+1],bytes[currentIndex+2],bytes[currentIndex+3]));
        end
        currentIndex = currentIndex+cs;
    end
    return table.concat(str);
end


local IKit = {
    MAXPLAYER = 24,
};

IKit.World = {
    PlayerConnect = {},
    PlayerDisconnect = {},
    RoundStart = {},
    PlayerSpawn = {},
    PlayerKilled = {},
    PlayerSignal  = {},
    Update =  {},
    PlayerAttack = {},
    ReceiveGameSave = {}
};


function IKit.World:addEventListener(type,event)
    table.insert(type,event);
end

function IKit.World:detachEventListener(type,event)
    for i = 1, #type, 1 do
        if type[i] == event then
            table.remove(type,i);
        end
    end
end

function IKit.World:forEach(type,...)
    for i = 1, #type, 1 do
        type[i](...);
    end
end

IKit.World:addEventListener(IKit.World.PlayerSignal,function(player, signal)
    if signal == -1 then
        for i = 1, #IKit.Command[player.name], 1 do
            IKit.Command[player.name][i] = string.bytesToString(IKit.Command[player.name][i]);
        end

        IKit.Command:execute(player,IKit.Command[player.name]);
        IKit.Command[player.name] = {};
        return;
    end
    if not IKit.Command[player.name] then
        IKit.Command[player.name] = {};
    end
    if signal == 0 then
        table.insert(IKit.Command[player.name],{});
    else 
        table.insert(IKit.Command[player.name][#IKit.Command[player.name]],signal);
    end
end);

IKit.Timer = {
    Task = {},
};

function IKit.Timer:schedule(task,delay,period)
    table.insert(self.Task,{handle = task,time = Game.GetTime() + delay,period = period});
end

function IKit.Timer:cancel()

end

function IKit.Timer:purge()
    Task = {}
end

IKit.World:addEventListener(IKit.World.Update,function(time)
    local i = 1;
    while i <= #IKit.Timer.Task do
        if IKit.Timer.Task[i].time < Game.GetTime() then
            IKit.Timer.Task[i].handle();
            if IKit.Timer.Task[i].period == nil then
                table.remove(IKit.Timer.Task,i);
            else
                IKit.Timer.Task[i].time = Game.GetTime() + IKit.Timer.Task[i].period;
            end
        end
        i = i + 1;
    end
end);


IKit.Player = {};

function IKit.Player:find(info)
    if type(info) == "number" then
        return Game.Player:Create (info);
    elseif type(info) == "string" then
        for i = 1, IKit.MAXPLAYER, 1 do
            local cp = Game.Player:Create(i);
            if cp~= nil and cp.name == info then
                return cp;
            end
        end
    end
end

IKit.Group = {};
IKit.Group["default"] = {"IKit"};
IKit.Group["guest"] = {" "};


function IKit.Group:setGroup(player,group)
    if not IKit.Group[group] then
        print("无该用户组");
        return; 
    end
    if type(player) == "userdata" then
            player.user.group = group;
        return;
    end
    IKit.Player:find(player).user.group = group;
end

function IKit.Group:addGroup(group)
    if(IKit.Group[group]) then
        error("已存在同名称的用户组");
    end
        IKit.Group[group] = {};
end

IKit.World:addEventListener(IKit.World.PlayerConnect,function(player)
    IKit.Group:setGroup(player,"default");
end);

IKit.Command = {};


IKit.Command["help"] = {condition = "IKit.help",behavior = function(player)
    print("帮助？？不存在的(￣▽￣)");
end};

IKit.Command["killme"] = {condition = "IKit.kill.me",behavior = function(player,args)
    player:Kill();
end};

IKit.Command["kill"] = {condition = "IKit.kill.player",behavior = function(player,args)
    IKit.Player:find(args[1]):Kill();
end};

IKit.Command["tp"] = {condition = "IKit.tp.player",behavior = function(player,args)
    player.position = IKit.Player:find(args[1]).position;
end};

IKit.Command["tppos"] = {condition = "IKit.tp.pos",behavior = function(player,args)
    player.position = {
        x = tonumber(args[1]),
        y = tonumber(args[2]),
        z = tonumber(args[3]),
    };
end};

IKit.Command["group"] = {condition = "IKit.group",behavior = function(player,args)
    IKit.Group:setGroup(IKit.Player:find(args[1]),args[2]);
end};


function IKit.Command: execute(player,command)
    local name = command[1];
    if IKit.Command[name] == nil then
        return;
    end

    local group = player.user.group;
    for i = 1, #IKit.Group[group], 1 do
        if(string.find(IKit.Command[name].condition,IKit.Group[group][i]) ~= nil) then
            table.remove(command,1);
            if not pcall(IKit.Command[name].behavior,player,command) then
                print("指令错误");
            end
            return;
        end
    end
    print("用户无权限执行该指令");
end


function Game.Rule:OnPlayerConnect(player)
    IKit.World:forEach(IKit.World.PlayerConnect,player);
end

function Game.Rule:OnPlayerDisconnect(player)
    IKit.World:forEach(IKit.World.PlayerDisconnect,player);
end

function Game.Rule:OnRoundStart()
    IKit.World:forEach(IKit.World.RoundStart);
end

function Game.Rule:OnPlayerSpawn(player)
    IKit.World:forEach(IKit.World.PlayerSpawn,player);
end

function Game.Rule:OnPlayerKilled(victim,killer,weapontype,hitbox)
    IKit.World:forEach(IKit.World.PlayerKilled,victim,killer,weapontype,hitbox);
end

function Game.Rule:OnPlayerSignal (player, signal)
    IKit.World:forEach(IKit.World.PlayerSignal,player,signal);
end

function Game.Rule:OnUpdate(time)
    IKit.World:forEach(IKit.World.Update,time);
end

function Game.Rule:OnPlayerAttack(victim,attacker,damage,weapontype,hitbox)
    IKit.World:forEach(IKit.World.PlayerAttack,victim,attacker,damage,weapontype,hitbox);
end

function Game.Rule:OnReceiveGameSave(player)
    IKit.World:forEach(IKit.World.ReceiveGameSave,player);
end
