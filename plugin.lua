debug = "hi"

function draw()
    imgui.Begin("sv addition")

    state.IsWindowHovered = imgui.IsWindowHovered()
    
    resetQueue()
    
    imgui.text(debug)
    
    if imgui.Button("test1") then
        local time = state.SongTime
        local svs1 = {}
        
        for i = 0, 2399 do
            table.insert(svs1, sv(time + i, math.sin(5 * i / 1000)))
        end
        table.insert(svs1, sv(time + 2400, 0))
        
        mergeSVs(svs1)
    end
    
    if imgui.Button("test2") then
        local time = state.SongTime
        local svs2 = {}
        
        for i = 0, 2399 do
            table.insert(svs2, sv(time + i, math.cos(i / 1000)))
        end
        table.insert(svs2, sv(time + 2400, 0))
        
        mergeSVs(svs2)
    end
    
    if imgui.Button("test3") then
        local time = state.SongTime
        local svs3 = {}
        
        
        for i = 0, 2399 do
            table.insert(svs3, sv(time + i, i * 0.1 / 1000))
        end
        table.insert(svs3, sv(time + 2400, 0))
        
        mergeSVs(svs3)
    end
    
    if imgui.Button("test4") then
        local time = state.SongTime
        local svs4 = {sv(time, 1),
                      sv(time + 600, -1),
                      sv(time + 1200, 2),
                      sv(time + 1800, -2),
                      sv(time + 2400, 0)}
                      
        mergeSVs(svs4)
    end
    
    if imgui.Button("test5") then
        local time = state.SongTime
        local svs5 = {}
        for i = 0, 2399 do
            table.insert(svs5, sv(time + i, i / 2400))
        end
        table.insert(svs5, sv(time + 2400, 0))
        
        mergeSVs(svs5)
    end
    
    if imgui.Button("test6") then
        local time = state.SongTime
        mergeSVs({sv(time, -.5)})
    end
    
    performQueue()
    
    imgui.End()
end

function sv(time, multiplier) return utils.CreateScrollVelocity(time, multiplier) end

function mergeSVs(svs)
    --for each sv given, increase map sv if no sv at that time
    for _, sv in pairs(svs) do
        --assumes initial scroll velocity is 1
        local mapsv = map.GetScrollVelocityAt(sv.StartTime) or utils.CreateScrollVelocity(-1e304, 1)
        if mapsv.StartTime ~= sv.StartTime then
            table.insert(add_sv_queue, utils.CreateScrollVelocity(sv.StartTime, mapsv.Multiplier + sv.Multiplier))
        end
    end
    
    --merging starts at first given sv, with map sv's before not changing
    local start = svs[1].StartTime
    
    --merging stops at last sv if last sv has velocity 0, otherwise stops at an sv with time infinity and velocity 0
    local stop
    if svs[#svs].Multiplier == 0 then
        stop = svs[#svs].StartTime
    else
        table.insert(svs, utils.CreateScrollVelocity(1e304, 0))
        stop = 1e304
    end

    local i = 1 --for keeping track of the relevant given sv
    
    --for each map sv within [start, stop), change according to relevant given sv
    for _, mapsv in pairs(map.ScrollVelocities) do
        if start <= mapsv.StartTime and mapsv.StartTime < stop then
            --make sure current map sv is between relevant given sv and next given sv
            while mapsv.StartTime >= svs[i+1].StartTime do
                i = i + 1
            end
            
            --in extreme cases with a bunch of different svs
            --removing then adding should be more efficient than directly changing
            --https://discord.com/channels/354206121386573824/810908988160999465/815724948256456704
            table.insert(remove_sv_queue, mapsv)
            table.insert(add_sv_queue, utils.CreateScrollVelocity(mapsv.StartTime, mapsv.Multiplier + svs[i].Multiplier))
        end
    end
end

function queue(type, arg1, arg2, arg3, arg4)
    arg1 = arg1 or nil
    arg2 = arg2 or nil
    arg3 = arg3 or nil
    arg4 = arg4 or nil

    local action = utils.CreateEditorAction(type, arg1, arg2, arg3, arg4)
    table.insert(action_queue, action)
end

function resetQueue()
    action_queue = {} --list of actions
    add_sv_queue = {} --list of svs
    remove_sv_queue = {} --list of svs
end

function performQueue()
    --create batch actions and add them to queue
    if #remove_sv_queue > 0 then queue(action_type.RemoveScrollVelocityBatch, remove_sv_queue) end
    if #add_sv_queue > 0 then queue(action_type.AddScrollVelocityBatch, add_sv_queue) end
    
    --perform actions in queue
    if #action_queue > 0 then actions.PerformBatch(action_queue) end
end