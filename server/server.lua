ESX = exports['es_extended']:getSharedObject()
local function SendWebhook(logType, embedData)
    local webhookURL = Config.WebhookURL[logType]
    
    if not webhookURL or webhookURL == 'YOUR_WEBHOOK_URL_HERE' then
        print(string.format('^3[FX-LOGS | WARN] Webhook URL ERROR in CONFIG for: %s', logType))
        return
    end

    local payload = {
        embeds = { embedData }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            if Config.Debug then
                print(string.format('^1[ERROR]^7 Failed to send webhook [%s]. Code: %d. Message: %s', logType, err, text))
            end
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Join Logs
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    if not Config.EnableLogs.Connect then return end

    local src = source
    local playerIp = GetPlayerEndpoint(src)
    local playerPing = GetPlayerPing(src)
    local currentTime = os.date("%H:%M:%S")

    local license = GetPlayerIdentifierByType(src, "license") or "N/A"
    local steam   = GetPlayerIdentifierByType(src, "steam") or "N/A"
    local discord = GetPlayerIdentifierByType(src, "discord") or "N/A"
    local live    = GetPlayerIdentifierByType(src, "live") or "N/A"
    local xbl     = GetPlayerIdentifierByType(src, "xbl") or "N/A"

    local embed = {
        title = "🔌 Player Connected",
        color = Config.EmbedColors.Join,
        description = string.format("**%s** has joined the server.", name),
        fields = {
            { name = "Server ID", value = tostring(src), inline = true },
            { name = "Ping", value = playerPing .. "ms", inline = true },
            { name = "Time", value = currentTime, inline = true },

            { name = "License", value = "`" .. license .. "`", inline = false },
            { name = "Steam", value = steam ~= "N/A" and "`" .. steam .. "`" or "Not Linked", inline = false },
            { name = "Discord", value = discord ~= "N/A" and "<@" .. discord:gsub("discord:", "") .. ">" or "Not Linked", inline = false },
            { name = "Rockstar Live", value = live ~= "N/A" and "`" .. live .. "`" or "Not Available", inline = false },
            { name = "Xbox Live", value = xbl ~= "N/A" and "`" .. xbl .. "`" or "Not Available", inline = false },

            { name = "IP", value = "`" .. (playerIp or "Unknown") .. "`", inline = false },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }

    SendWebhook('Join', embed)
end)


-- Leave Logs
AddEventHandler('playerDropped', function(reason)
    if not Config.EnableLogs.PlayerLeave then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    local src = source
    local name = GetPlayerName(src)
    local currentTime = os.date("%H:%M:%S")

    if xPlayer then
        local identifier = xPlayer.identifier
        local playerIp = GetPlayerEndpoint(src)
        local playerPing = GetPlayerPing(src)

        local embed = {
            title = "❌ Player Disconnected",
            color = Config.EmbedColors.Leave,
            description = "**" .. name .. "** has left the server.",
            fields = {
                { name = "Server ID", value = tostring(src), inline = true },
                { name = "Ping", value = tostring(playerPing) .. "ms", inline = true },
                { name = "Time", value = currentTime, inline = true },
                { name = "Identifier", value = "`" .. identifier .. "`", inline = false },
                { name = "Reason", value = reason, inline = false },
            },
            footer = { text = "FX LOGS | fxDopa" }
        }

        SendWebhook('Leave', embed)
    else
        print('^7 Player Disconnected On Loading Screen')
    end
end)

AddEventHandler('chatMessage', function(src, name, message)
    if not Config.EnableLogs.Chat then return end

    local embed = {
        title = "💬 Chat Message",
        color = Config.EmbedColors.Chat,
        description = "**" .. name .. " [" .. src .. "]** said:",
        fields = {
            { name = "Message", value = message, inline = false },
        },
        footer = { text = "FX LOGS | Time: " .. os.date("%H:%M:%S") }
    }


    SendWebhook('Chat', embed)
end)

-- Aim Logs
RegisterServerEvent('fx-logs:aimlogs')
AddEventHandler('fx-logs:aimlogs', function(pedId)
    if not Config.EnableLogs.Aim then return end

    local src = source
    local name = GetPlayerName(src)
    local targetName = GetPlayerName(pedId)
    local currentTime = os.date("%H:%M:%S")

    local embed = {
        title = "🎯 Aiming Log",
        color = Config.EmbedColors.Aim,
        description = "**" .. name .. "** is aiming at **" .. targetName .. "**.",
        fields = {
            { name = "Aimer", value = name .. " `[" .. src .. "]`", inline = true },
            { name = "Target", value = targetName .. " `[" .. pedId .. "]`", inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }

    SendWebhook('Aim', embed)
end)

RegisterServerEvent('fx-logs:killlogs')
AddEventHandler('fx-logs:killlogs', function(message, weapon)
    if not Config.EnableLogs.Kill then return end

    local currentTime = os.date("%H:%M:%S")

    local embed = {
        title = "💀 Kill/Death Log",
        color = Config.EmbedColors.Kill,
        description = message,
        fields = {
            { name = "Weapon", value = weapon, inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }
    
    SendWebhook('Kill', embed)
end)

local ServerExplotions = {}
local explosionTypes = {
	'GRENADE', 'GRENADELAUNCHER', 'STICKYBOMB', 'MOLOTOV', 'ROCKET', 'TANKSHELL', 'HI_OCTANE', 'CAR', 'PLANE', 'PETROL_PUMP', 'BIKE', 'DIR_STEAM', 'DIR_FLAME', 'DIR_GAS_CANISTER', 'GAS_CANISTER', 'BOAT', 'SHIP_DESTROY', 'TRUCK', 'BULLET', 'SMOKEGRENADELAUNCHER', 'SMOKEGRENADE', 'BZGAS', 'FLARE', 'EXTINGUISHER', 'PROGRAMMABLEAR', 'TRAIN', 'BARREL', 'PROPANE', 'BLIMP', 'DIR_FLAME_EXPLODE', 'TANKER', 'PLANE_ROCKET', 'VEHICLE_BULLET', 'GAS_TANK', 'BIRD_CRAP', 'RAILGUN', 'BLIMP2', 'FIREWORK', 'SNOWBALL', 'PROXMINE', 'VALKYRIE_CANNON', 'AIR_DEFENCE', 'PIPEBOMB', 'VEHICLEMINE', 'EXPLOSIVEAMMO', 'APCSHELL', 'BOMB_CLUSTER', 'BOMB_GAS', 'BOMB_INCENDIARY', 'BOMB_STANDARD', 'TORPEDO', 'TORPEDO_UNDERWATER', 'BOMBUSHKA_CANNON', 'BOMB_CLUSTER_SECONDARY', 'HUNTER_BARRAGE', 'HUNTER_CANNON', 'ROGUE_CANNON', 'MINE_UNDERWATER', 'ORBITAL_CANNON', 'BOMB_STANDARD_WIDE', 'EXPLOSIVEAMMO_SHOTGUN', 'OPPRESSOR2_CANNON', 'MORTAR_KINETIC', 'VEHICLEMINE_KINETIC', 'VEHICLEMINE_EMP', 'VEHICLEMINE_SPIKE', 'VEHICLEMINE_SLICK', 'VEHICLEMINE_TAR', 'SCRIPT_DRONE', 'RAYGUN', 'BURIEDMINE', 'SCRIPT_MISSIL'
}
ServerExplotions.ExplosionNames = {
	['GRENADE'] = 'Grenade',
	['GRENADELAUNCHER'] = 'Grenade Launcher',
	['STICKYBOMB'] = 'Sticky Bomb',
	['MOLOTOV'] = 'Molotov',
	['ROCKET'] = 'Rocket',
	['TANKSHELL'] = 'Tank Shell',
	['HI_OCTANE'] = 'HI_OCTANE',
	['CAR'] = 'Vehicle: Car',
	['PLANE'] = 'vehicle: Plane',
	['PETROL_PUMP'] = 'Petrol Pump',
	['BIKE'] = 'Vehicle: Bike',
	['DIR_STEAM'] = 'DIR_STEAM',
	['DIR_FLAME'] = 'DIR_FLAME',
	['DIR_GAS_CANISTER'] = 'Gas Canister',
	['GAS_CANISTER'] = 'Gas Canister',
	['BOAT'] = 'Vehicle: Boat',
	['SHIP_DESTROY'] = 'Vehicle: Ship',
	['TRUCK'] = 'Vehicle: Truck',
	['BULLET'] = 'Exploding Bullet',
	['SMOKEGRENADELAUNCHER'] = 'Smoke Grenade (Launcher)',
	['SMOKEGRENADE'] = 'Smoke Grenade',
	['BZGAS'] = 'BZ Gas',
	['FLARE'] = 'Flare',
	['EXTINGUISHER'] = 'Fire Extinguiser',
	['PROGRAMMABLEAR'] = 'PROGRAMMABLEAR',
	['TRAIN'] = 'Vehicle: Train',
	['BARREL'] = 'Barrel',
	['PROPANE'] = 'Propane',
	['BLIMP'] = 'Blimp',
	['DIR_FLAME_EXPLODE'] = 'DIR_FLAME_EXPLODE',
	['TANKER'] = 'Vehicle: Tanker',
	['PLANE_ROCKET'] = 'Plane Rocket',
	['VEHICLE_BULLET'] = 'Vehicle Bullet',
	['GAS_TANK'] = 'Gas Tank',
	['BIRD_CRAP'] = 'BIRD_CRAP',
	['RAILGUN'] = 'Railgun',
	['BLIMP2'] = 'BLIMP2',
	['FIREWORK'] = 'Fireworks',
	['SNOWBALL'] = 'Snowball',
	['PROXMINE'] = 'Proximity Mine',
	['VALKYRIE_CANNON'] = 'Valkyrie Cannon',
	['AIR_DEFENCE'] = 'Air Defence',
	['PIPEBOMB'] = 'Pipe Bomb',
	['VEHICLEMINE'] = 'Vehicle Mine',
	['EXPLOSIVEAMMO'] = 'Explosive Ammo',
	['APCSHELL'] = 'APC Shell',
	['BOMB_CLUSTER'] = 'Bomb Cluster',
	['BOMB_GAS'] = 'Bomb Gas',
	['BOMB_INCENDIARY'] = 'Bomb Incendiary',
	['BOMB_STANDARD'] = 'Bomb',
	['TORPEDO'] = 'Torpedo',
	['TORPEDO_UNDERWATER'] = 'Torpedo Under Water',
	['BOMBUSHKA_CANNON'] = 'BOMBUSHKA_CANNON',
	['BOMB_CLUSTER_SECONDARY'] = 'BOMB_CLUSTER_SECONDARY',
	['HUNTER_BARRAGE'] = 'HUNTER_BARRAGE',
	['HUNTER_CANNON'] = 'HUNTER_CANNON',
	['ROGUE_CANNON'] = 'ROGUE_CANNON',
	['MINE_UNDERWATER'] = 'MINE_UNDERWATER',
	['ORBITAL_CANNON'] = 'ORBITAL_CANNON',
	['BOMB_STANDARD_WIDE'] = 'BOMB_STANDARD_WIDE',
	['EXPLOSIVEAMMO_SHOTGUN'] = 'EXPLOSIVEAMMO_SHOTGUN',
	['OPPRESSOR2_CANNON'] = 'OPPRESSOR2_CANNON',
	['MORTAR_KINETIC'] = 'MORTAR_KINETIC',
	['VEHICLEMINE_KINETIC'] = 'VEHICLEMINE_KINETIC',
	['VEHICLEMINE_EMP'] = 'VEHICLEMINE_EMP',
	['VEHICLEMINE_SPIKE'] = 'VEHICLEMINE_SPIKE',
	['VEHICLEMINE_SLICK'] = 'VEHICLEMINE_SLICK',
	['VEHICLEMINE_TAR'] = 'VEHICLEMINE_TAR',
	['SCRIPT_DRONE'] = 'SCRIPT_DRONE',
	['RAYGUN'] = 'RAYGUN',
	['BURIEDMINE'] = 'BURIEDMINE',
	['SCRIPT_MISSIL'] = 'SCRIPT_MISSIL'
}
local function GetExplosionName(explosionTypeIndex)
    local typeString = explosionTypes[explosionTypeIndex + 1]
    if typeString then
        return ServerExplotions.ExplosionNames[typeString] or typeString
    end
    return 'Unknown'
end

-- ===================================================================
-- [[ RESOURCE LOGS ]]
-- ===================================================================

local webhookQueue = {}
local isProcessing = false

function QueueWebhook(logType, embedData)
    table.insert(webhookQueue, {logType = logType, embed = embedData})
    ProcessQueue()
end
function ProcessQueue()
    if isProcessing then return end
    isProcessing = true

    Citizen.CreateThread(function()
        while #webhookQueue > 0 do
            local data = table.remove(webhookQueue, 1)
            SendWebhook(data.logType, data.embed)
            Citizen.Wait(1500) -- DONT CHANGE
        end
        isProcessing = false
    end)
end
AddEventHandler('onResourceStart', function(resourceName)
    if not Config.EnableLogs.Resource then return end

    local currentTime = os.date("%H:%M:%S")
    local embed = {
        title = "🟢 Resource Started",
        color = Config.EmbedColors.Resource,
        description = string.format("The resource **%s** has been started.", resourceName),
        fields = {
            { name = "Resource", value = resourceName, inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | Server Status" }
    }

    QueueWebhook('Resource', embed)
end)

AddEventHandler('onResourceStop', function (resourceName)
    if not Config.EnableLogs.Resource then return end

    local currentTime = os.date("%H:%M:%S")
    
    local embed = {
        title = "🔴 Resource Stopped",
        color = Config.EmbedColors.Resource,
        description = string.format("The resource **%s** has been stopped.", resourceName),
        fields = {
            { name = "Resource", value = resourceName, inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | Resource Stop" }
    }
    
    SendWebhook('Resource', embed)
end)


RegisterNetEvent("esx:playerLoaded", function(player, xPlayer, isNew)
    if not Config.EnableLogs.NewPlayer then return end
    local currentTime = os.date("%H:%M:%S")

    if (isNew) then
        local embed = {
            title = "👤 New Player Registered",
            color = Config.EmbedColors.NewPlayer,
            description = string.format("Player **%s** has created their character for the first time.", GetPlayerName(player)),
            fields = {
                { name = "Server ID", value = tostring(player), inline = true },
                { name = "Time", value = currentTime, inline = true },
                { name = "Identifier", value = xPlayer.identifier, inline = false }
            },
            footer = { text = "FX LOGS | New Player" }
        }

        SendWebhook('NewPlayer', embed)
    end
end)

-- ===================================================================
-- [[ EXPLOSION LOGS ]]
-- ===================================================================

AddEventHandler('explosionEvent', function(source, ev)
    if not Config.EnableLogs.Explosion then return end

    local src = source
    local explosionName = GetExplosionName(ev.explosionType)
    local currentTime = os.date("%H:%M:%S")

    local playerName = (src > 0) and GetPlayerName(src) or "World"
    local playerID = (src > 0) and tostring(src) or "0"

    local embed = {
        title = "💥 Explosion Log",
        color = Config.EmbedColors.Explosion,
        description = string.format("**%s** has caused a **%s** explosion.", playerName, explosionName),
        fields = {
            { name = "Source", value = playerName .. " `[" .. playerID .. "]`", inline = true },
            { name = "Explosion Type", value = explosionName, inline = true },
            { name = "Coordinates", value = string.format("%.1f, %.1f, %.1f", ev.pos.x, ev.pos.y, ev.pos.z), inline = false },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }
    
    SendWebhook('Explosion', embed)
end)

-- ===================================================================
-- [[ SHOOTING LOGS ]]
-- ===================================================================

RegisterServerEvent('fx-logs:shootinglogs')
AddEventHandler('fx-logs:shootinglogs', function(weaponName, shotCount)
    if not Config.EnableLogs.Shooting then return end
    
    local src = source
    local name = GetPlayerName(src)
    local currentTime = os.date("%H:%M:%S")

    local embed = {
        title = "🔫 Shooting Log",
        color = Config.EmbedColors.Shooting,
        description = string.format("**%s** has fired **%d** times with **%s**.", name, shotCount, weaponName),
        fields = {
            { name = "Player", value = name .. " `[" .. src .. "]`", inline = true },
            { name = "Weapon", value = weaponName, inline = true },
            { name = "Shots Fired", value = tostring(shotCount), inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }

    SendWebhook('Shooting', embed)
end)

-- ===================================================================
-- [[ DAMAGE LOGS ]]
-- ===================================================================

RegisterServerEvent('fx-logs:damagelogs')
AddEventHandler('fx-logs:damagelogs', function(damageType, damageAmount)
    if not Config.EnableLogs.Damage then return end -- Double check on server

    local src = source
    local name = GetPlayerName(src)
    local playerPed = GetPlayerPed(src)
    local currentTime = os.date("%H:%M:%S")

    local cause = GetPedSourceOfDamage(playerPed)
    local causeName = "World/Unknown"
    local causeID = "0"
    local dType = GetEntityType(cause)

    if dType == 1 then -- Is a Ped
        if IsPedAPlayer(cause) then
            local targetPlayerID = getPlayerId(cause)
            if targetPlayerID then
                causeName = GetPlayerName(targetPlayerID)
                causeID = tostring(targetPlayerID)
            end
        else
            causeName = "NPC/AI"
        end
    elseif dType == 2 then -- Is a Vehicle
        local driver = GetPedInVehicleSeat(cause, -1)
        if IsPedAPlayer(driver) then
            local targetPlayerID = getPlayerId(driver)
            if targetPlayerID then
                causeName = GetPlayerName(targetPlayerID) .. " (Vehicle)"
                causeID = tostring(targetPlayerID)
            end
        else
            causeName = "Vehicle (NPC/AI)"
        end
    elseif dType == 3 then
        causeName = "Object"
    elseif dType == 0 then
        causeName = "Self-Inflicted/Environment Damage"
        causeID = tostring(src)
    end
    
    local embed = {
        title = "💔 Damage Log",
        color = Config.EmbedColors.Damage,
        description = string.format("**%s** has received **%d** damage to their **%s**.", name, damageAmount, damageType),
        fields = {
            { name = "Victim", value = name .. " `[" .. src .. "]`", inline = true },
            { name = "Instigator/Cause", value = causeName .. " `[" .. causeID .. "]`", inline = true },
            { name = "Damage", value = tostring(damageAmount) .. " (" .. damageType .. ")", inline = true },
            { name = "Time", value = currentTime, inline = true },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }

    SendWebhook('Damage', embed)
end)

print('^7===============================')
print(' LOGS STARTED | ^2FX-Logs^7 ')
print(' ^3by fxDopa^7 ')
print('^7===============================')