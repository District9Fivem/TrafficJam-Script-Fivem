local isHighTraffic = false

RegisterCommand('toggletrafficdensity', function()
    -- Request the server to check for the permission and toggle the traffic density
    TriggerServerEvent('trafficdensity:checkPermission')
end, false)

RegisterNetEvent('trafficdensity:toggle')
AddEventHandler('trafficdensity:toggle', function()
    isHighTraffic = not isHighTraffic

    if isHighTraffic then
        -- Increase vehicle density for driving NPCs and parked vehicles
        SetVehicleDensityMultiplierThisFrame(300.0) -- Set density multiplier for NPC vehicles to 300
        SetRandomVehicleDensityMultiplierThisFrame(300.0) -- Set random NPC vehicle density to 300
        SetParkedVehicleDensityMultiplierThisFrame(65.0) -- Set parked vehicle density to 65

        -- Add more driving vehicles to simulate extreme heavy traffic
        TriggerEvent('trafficdensity:addVehicles')
        TriggerEvent('chat:addMessage', { args = { '[Traffic]', 'Traffic density increased significantly!' } })
    else
        -- Reset vehicle density
        SetVehicleDensityMultiplierThisFrame(1.0) 
        SetRandomVehicleDensityMultiplierThisFrame(1.0)
        SetParkedVehicleDensityMultiplierThisFrame(1.0)

        -- Clear the spawned driving vehicles, but keep the player's vehicle
        TriggerEvent('trafficdensity:removeVehicles')
        TriggerEvent('chat:addMessage', { args = { '[Traffic]', 'Traffic density reset to normal.' } })
    end
end)

-- Function to add more driving NPC vehicles to the road
AddEventHandler('trafficdensity:addVehicles', function()
    Citizen.CreateThread(function()
        while isHighTraffic do
            Citizen.Wait(1000) -- Reduced wait time to 1 second between spawns for faster vehicle creation

            -- Spawn additional vehicles
            for i = 1, 25 do -- Increase the number of vehicles spawned each cycle
                local vehicleHash = GetHashKey("adder") -- Change to your desired vehicle model
                RequestModel(vehicleHash)

                while not HasModelLoaded(vehicleHash) do
                    Citizen.Wait(500) -- Wait for the model to load
                end

                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                -- Spawn vehicles at random coordinates around the player
                local spawnX = playerCoords.x + math.random(-200, 200) -- Widen the spawn area
                local spawnY = playerCoords.y + math.random(-200, 200)
                local spawnZ = playerCoords.z

                local vehicle = CreateVehicle(vehicleHash, spawnX, spawnY, spawnZ, math.random(0, 360), true, false)

                -- Make the vehicle a mission entity so it won't despawn
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleNeedsToBeHotwired(vehicle, false)
                SetVehicleHasBeenOwnedByPlayer(vehicle, true)

                -- Set a random driver
                local driverPedHash = GetHashKey("s_m_m_traffic") -- Use a traffic ped model
                RequestModel(driverPedHash)

                while not HasModelLoaded(driverPedHash) do
                    Citizen.Wait(500)
                end

                local driver = CreatePed(1, driverPedHash, spawnX, spawnY, spawnZ, math.random(0, 360), true, false)
                TaskWarpPedIntoVehicle(driver, vehicle, -1) -- Put the ped in the driver's seat
                SetDriverAbility(driver, 1) -- Make the driver able to drive
                SetDriverAggressiveness(driver, 1.0) -- Make the driver aggressive
                SetPedNeverLeavesVehicle(driver, true) -- Prevent the driver from leaving the vehicle
            end
        end
    end)
end)

-- Function to remove all spawned vehicles when traffic density is turned off
AddEventHandler('trafficdensity:removeVehicles', function()
    Citizen.CreateThread(function()
        local vehicles = GetAllVehicles()
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false) -- Get the player's current vehicle

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) and vehicle ~= playerVehicle then
                DeleteEntity(vehicle) -- Only delete vehicles that are not the player's
            end
        end
    end)
end)

-- Utility function to get all vehicles in the game
function GetAllVehicles()
    local vehicles = {}
    for vehicle in EnumerateVehicles() do
        table.insert(vehicles, vehicle)
    end
    return vehicles
end

-- Helper function to enumerate all vehicles
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end
