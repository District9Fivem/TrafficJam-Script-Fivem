local trafficPermission = "trafficdensity.toggle" -- Define the ACE permission

RegisterNetEvent('trafficdensity:checkPermission')
AddEventHandler('trafficdensity:checkPermission', function()
    local _source = source
    if IsPlayerAceAllowed(_source, trafficPermission) then
        TriggerClientEvent('trafficdensity:toggle', _source)
    else
        TriggerClientEvent('chat:addMessage', _source, { args = { '[Traffic]', 'You do not have permission to toggle traffic density.' } })
    end
end)
