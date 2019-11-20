IKit = {
    
}

IKit.Timer = {
    Task = {},
};

function IKit.Timer:schedule(id,task,delay,period)
    table.insert(self.Task,{id = id,handle = task,time = Game.GetTime() + delay,period = period});
    return self.Task[#self.Task];
end


function IKit.Timer:find(id)
    for i = 1, #IKit.Timer.Task, 1 do
        if IKit.Timer.Task[i].id == id then
            return IKit.Timer.Task[i];
        end
    end
    return nil;
end

function IKit.Timer:cancel(id)
    for i = 1, #IKit.Timer.Task, 1 do
        if IKit.Timer.Task[i].id == id then
            table.remove(IKit.Timer.Task,i);
            return;
        end
    end
end
function IKit.Timer:purge()
    Task = {}
end

IKit.Event = {
    Chat  = {},
    RoundStart={},
    Spawn = {},
    Killed = {},
    Update =  {},
}

function IKit.Event:addEventListener(type,event)
    table.insert(type,event);
end

function IKit.Event:detachEventListener(type,event)
    for i = 1, #type, 1 do
        if type[i] == event then
            table.remove(type,i);
        end
    end
end

function IKit.Event:forEach(type,...)
    for i = 1, #type, 1 do
        type[i](...);
    end
end


function UI.Event:OnChat (text)
    IKit.Event:forEach(IKit.Event.Chat,text);
end


IKit.Event:addEventListener(IKit.Event.Chat,function(text)
    if string.sub(text,1,1) == '/' and #text > 1 then
        UI.Signal(0);
        for i = 2, #text, 1 do
            if string.sub(text,i,i) ~= ' ' then
                UI.Signal(string.byte(text,i));
            elseif string.sub(text,i-1,i-1) ~= ' ' and string.sub(text,i-1,i-1) ~= '/' then
                UI.Signal(0);
            end
        end
        UI.Signal(-1);
    end
end);




