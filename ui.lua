IKit = {
    
}

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




