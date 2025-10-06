if Config.ESX then
    ESX = exports['es_extended']:getSharedObject()
end

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

    local src = source
    local name = GetPlayerName(src)
    local currentTime = os.date("%H:%M:%S")

    local identifier = GetPlayerIdentifierByType(src, "discord") or "N/A"
    local playerIp = GetPlayerEndpoint(src)
    local playerPing = GetPlayerPing(src)

    local embed = {
        title = "❌ Player Disconnected",
        color = Config.EmbedColors.Leave,
        description = "**" .. name .. " (ID: " .. tostring(src) .. ")** has left the server.",
        fields = {
            { name = "Ping", value = tostring(playerPing) .. "ms", inline = true },
            { name = "Time", value = currentTime, inline = true },
            { name = "Identifier", value = "`" .. identifier .. "`", inline = false },
            { name = "Reason", value = reason, inline = false },
        },
        footer = { text = "FX LOGS | fxDopa" }
    }

    SendWebhook('Leave', embed)
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

if Config.ESX then 
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
end
-- ===================================================================
-- [[ EXPLOSION LOGS ]]
-- ===================================================================

AddEventHandler('explosionEvent', function(source, ev)
    if not Config.EnableLogs.Explosion then return end

    local src = source
    local explosionName = GetExplosionName(ev.explosionType)
    local currentTime = os.date("%H:%M:%S")

    local playerName = GetPlayerName(src)
    local playerID = tostring(src)

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
            local targetPlayerID = GetPlayerServerId(src)
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
            local targetPlayerID = GetPlayerServerId(src)
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

-- ===================================================================
-- [[ TX ADMIN LOGS ]]
-- ===================================================================

-- ===================================================================================
--                       IMPLEMENTACIÓN DE EVENTOS DE TXADMIN
-- ===================================================================================

-- Función auxiliar para preparar un embed
local function CreateTxAdminEmbed(logType, title, description, fields)
    local embed = {
        title = title,
        description = description,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = { text = "txAdmin Log | " .. logType },
        fields = fields or {},
    }
    return embed
end

-- ===================================================================================
-- EVENTOS DE ANUNCIO Y SERVIDOR
-- ===================================================================================

AddEventHandler('txAdmin:events:announcement', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Mensaje', value = eventData.message, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Anuncio Global de txAdmin', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Retraso (ms)', value = eventData.delay, inline = true },
            { name = 'Mensaje', value = eventData.message, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Servidor a punto de apagarse', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Segundos Restantes', value = eventData.secondsRemaining, inline = true },
            { name = 'Mensaje (Traducido)', value = eventData.translatedMessage, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Reinició Programado Detectado', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:scheduledRestartSkipped', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local temporaryStatus = eventData.temporary and 'Sí (Temporal)' or 'No (Permanente en Config)'
        local fields = {
            { name = 'Administrador', value = eventData.author, inline = true },
            { name = 'Restarts Programado', value = string.format('Originalmente faltaban %s segundos.', eventData.secondsRemaining), inline = true },
            { name = 'Temporal', value = temporaryStatus, inline = true },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Reinició Programado Omitido', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

-- ===================================================================================
-- EVENTOS RELACIONADOS CON JUGADORES
-- ===================================================================================

AddEventHandler('txAdmin:events:playerBanned', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local permStatus = eventData.expiration == false and 'Permanente' or string.format('<t:%s:F>', math.floor(eventData.expiration / 1000))
        local fields = {
            { name = 'Jugador', value = eventData.targetName, inline = true },
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Expiración', value = permStatus, inline = true },
            { name = 'Razón', value = eventData.reason, inline = false },
            { name = 'IDs Afectadas', value = table.concat(eventData.targetIds, ', '), inline = false },
            { name = 'Mensaje de Kick', value = eventData.kickMessage or 'N/A', inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', '🚨 Jugador BANEADO por txAdmin 🚨', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:playerDirectMessage', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Target (NetID)', value = eventData.target, inline = true },
            { name = 'Mensaje', value = eventData.message, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Mensaje Directo (DM) Enviado', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:playerHealed', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local target = eventData.target == -1 and 'Servidor Completo' or 'NetID: ' .. eventData.target
        local fields = {
            { name = 'Administrador', value = eventData.author, inline = true },
            { name = 'Target', value = target, inline = true },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Acción de Curar (Heal) Ejecutada', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:playerKicked', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local target = eventData.target == -1 and 'Servidor Completo' or 'NetID: ' .. eventData.target
        local fields = {
            { name = 'Target', value = target, inline = true },
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Razón', value = eventData.reason, inline = false },
            { name = 'Mensaje de Drop', value = eventData.dropMessage, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Jugador Kickeado/Expulsado', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:playerWarned', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Jugador', value = eventData.targetName, inline = true },
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Action ID', value = eventData.actionId, inline = true },
            { name = 'Razón', value = eventData.reason, inline = false },
            { name = 'IDs', value = table.concat(eventData.targetIds, ', ') or 'N/A', inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', '⚠️ Jugador Advertido por txAdmin ⚠️', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

-- ===================================================================================
-- EVENTOS DE WHITELIST
-- ===================================================================================

AddEventHandler('txAdmin:events:whitelistPlayer', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Acción', value = string.upper(eventData.action), inline = true },
            { name = 'Administrador', value = eventData.adminName, inline = true },
            { name = 'Jugador', value = eventData.playerName, inline = false },
            { name = 'License', value = eventData.license, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Whitelist (' .. string.upper(eventData.action) .. ') en Base de Datos', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:whitelistPreApproval', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Acción', value = string.upper(eventData.action), inline = true },
            { name = 'Administrador', value = eventData.adminName, inline = true },
            { name = 'Identificador', value = eventData.identifier, inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Pre-Aprobación de Whitelist', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:whitelistRequest', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local description = string.format('Acción: **%s**', string.upper(eventData.action))
        
        local fields = {}
        if eventData.playerName then table.insert(fields, { name = 'Jugador', value = eventData.playerName, inline = true }) end
        if eventData.adminName then table.insert(fields, { name = 'Administrador', value = eventData.adminName, inline = true }) end
        if eventData.requestId then table.insert(fields, { name = 'Request ID', value = eventData.requestId, inline = true }) end
        if eventData.license then table.insert(fields, { name = 'License', value = eventData.license, inline = false }) end

        local embedData = CreateTxAdminEmbed('AdminActions', 'Evento de Solicitud de Whitelist', description, fields)
        SendWebhook('AdminActions', embedData)
    end
end)

-- ===================================================================================
-- OTROS EVENTOS
-- ===================================================================================

AddEventHandler('txAdmin:events:actionRevoked', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Acción Revocada', value = string.upper(eventData.actionType), inline = true },
            { name = 'Revocado Por', value = eventData.revokedBy, inline = true },
            { name = 'Autor Original', value = eventData.actionAuthor, inline = true },
            { name = 'Jugador', value = eventData.playerName or 'N/A', inline = true },
            { name = 'Action ID', value = eventData.actionId, inline = true },
            { name = 'Razón Original', value = eventData.actionReason, inline = false },
            { name = 'IDs Afectadas', value = table.concat(eventData.playerIds, ', ') or 'N/A', inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', '🚫 Acción Revocada (Ban/Warn) 🚫', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:adminAuth', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local status = eventData.isAdmin and 'AUTENTICADO' or 'PERMISOS REVOCADOS'
        local netid = eventData.netid == -1 and 'Todos los Admins (Reauth Forzado)' or 'NetID: ' .. eventData.netid
        local description = string.format('El admin **%s** ha cambiado su estado de autenticación.', eventData.username or 'Desconocido')
        
        local fields = {
            { name = 'Estado', value = status, inline = true },
            { name = 'NetID', value = netid, inline = true },
            { name = 'Username txAdmin', value = eventData.username or 'N/A', inline = true },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Cambio de Estado de Admin', description, fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:adminsUpdated', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local description = string.format('La lista de administradores online ha sido forzada a refrescarse. Admins online: **%d**', #eventData)
        local fields = {
            { name = 'NetIDs de Admins Online', value = table.concat(eventData, ', ') or 'Ninguno', inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Lista de Admins Actualizada', description, fields)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:configChanged', function()
    if Config.EnableLogs.txAdminActions then
        local embedData = CreateTxAdminEmbed('AdminActions', 'Configuración de txAdmin Cambiada', 'Se ha cambiado la configuración de txAdmin (por ejemplo, idioma).', nil)
        SendWebhook('AdminActions', embedData)
    end
end)

AddEventHandler('txAdmin:events:consoleCommand', function(eventData)
    if Config.EnableLogs.txAdminActions then
        local fields = {
            { name = 'Autor', value = eventData.author, inline = true },
            { name = 'Canal', value = eventData.channel, inline = true },
            { name = 'Comando', value = '`' .. eventData.command .. '`', inline = false },
        }
        local embedData = CreateTxAdminEmbed('AdminActions', 'Comando Ejecutado en Consola (txAdmin)', '', fields)
        SendWebhook('AdminActions', embedData)
    end
end)


print('^7===============================')
print(' LOGS STARTED | ^2FX-Logs^7 ')
print(' ^3by fxDopa^7 ')

print('^7===============================')
