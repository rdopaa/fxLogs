ESX = exports['es_extended']:getSharedObject()

--Aim Logs
Citizen.CreateThread(function()
    local lastPedAimed
	local playerPed = nil
    while true do
        Citizen.Wait(500)

        playerPed = PlayerPedId()
        
        if IsPedArmed(playerPed, 4) then
            local isAiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(-1))
            
            if isAiming then
                if DoesEntityExist(targetPed) and IsEntityAPed(targetPed) and IsPedAPlayer(targetPed) and targetPed ~= lastPedAimed then
                    lastPedAimed = targetPed

                    local targetId = NetworkGetPlayerIndexFromPed(targetPed)
                    if targetId then
                        local pedId = GetPlayerServerId(targetId)
                        
                        if pedId and (pedId > 0) then
                            TriggerServerEvent('fx-logs:aimlogs', pedId)
                        end
                    end
                elseif not targetPed and lastPedAimed then
                    lastPedAimed = nil
                end
            else
                lastPedAimed = nil
            end
        end
    end 
end)

local playerArmor = 0

Citizen.CreateThread(function()
	local DeathReason, Killer, DeathCauseHash, Weapon
	local playerped = nil

	while true do
		playerped = PlayerPedId()
		
		if IsEntityDead(playerped) then
			local PedKiller = GetPedSourceOfDeath(playerped)
			DeathCauseHash = GetPedCauseOfDeath(playerped)
			Weapon = WeaponNames[tostring(DeathCauseHash)]

			if IsEntityAPed(PedKiller) and IsPedAPlayer(PedKiller) then
				Killer = NetworkGetPlayerIndexFromPed(PedKiller)
			elseif IsEntityAVehicle(PedKiller) and IsEntityAPed(GetPedInVehicleSeat(PedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(PedKiller, -1)) then
				Killer = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(PedKiller, -1))
			end
			
			if (Killer == PlayerId()) then
				DeathReason = 'committed suicide'
			elseif (Killer == nil) then
				DeathReason = 'died'
			else
				if IsMelee(DeathCauseHash) then
					DeathReason = 'murdered'
				elseif IsTorch(DeathCauseHash) then
					DeathReason = 'torched'
				elseif IsKnife(DeathCauseHash) then
					DeathReason = 'knifed'
				elseif IsPistol(DeathCauseHash) then
					DeathReason = 'pistoled'
				elseif IsSub(DeathCauseHash) then
					DeathReason = 'riddled'
				elseif IsRifle(DeathCauseHash) then
					DeathReason = 'rifled'
				elseif IsLight(DeathCauseHash) then
					DeathReason = 'machine gunned'
				elseif IsShotgun(DeathCauseHash) then
					DeathReason = 'pulverized'
				elseif IsSniper(DeathCauseHash) then
					DeathReason = 'sniped'
				elseif IsHeavy(DeathCauseHash) then
					DeathReason = 'obliterated'
				elseif IsMinigun(DeathCauseHash) then
					DeathReason = 'shredded'
				elseif IsBomb(DeathCauseHash) then
					DeathReason = 'bombed'
				elseif IsVeh(DeathCauseHash) then
					DeathReason = 'mowed over'
				elseif IsVK(DeathCauseHash) then
					DeathReason = 'flattened'
				else
					DeathReason = 'killed'
				end
			end
			
			if DeathReason == 'committed suicide' or DeathReason == 'died' then
				TriggerServerEvent('fx-logs:killlogs', GetPlayerName(PlayerId()) .. ' ' .. DeathReason .. '.', Weapon)
			else
				TriggerServerEvent('fx-logs:killlogs', GetPlayerName(Killer) .. '['..GetPlayerServerId(Killer).. '] ' .. DeathReason .. ' ' .. GetPlayerName(PlayerId()) .. '['..GetPlayerServerId(PlayerId())..']', Weapon)
			end
			Killer = nil
			DeathReason = nil
			DeathCauseHash = nil
			Weapon = nil
		else
			playerArmor = GetPedArmour(playerped)
		end
		
		while IsEntityDead(playerped) do
			Citizen.Wait(0)
		end

        Wait(500)
	end
end)


-- [[ Shooting logs. ]]
if Config.EnableLogs and Config.EnableLogs.Shooting then
	Citizen.CreateThread(function()
		local fireWeapon = nil
		local timeout = 0
		local fireCount = 0
		local playerped = nil

		while true do
			Citizen.Wait(100)
			playerped = PlayerPedId()

			if IsPedShooting(playerped) then
				fireWeapon = GetSelectedPedWeapon(playerped)
				fireCount = fireCount + 1
				timeout = 50
			elseif not IsPedShooting(playerped) and fireCount ~= 0 and timeout ~= 0 then
				timeout = timeout - 1 

				if fireWeapon ~= GetSelectedPedWeapon(playerped) then
					timeout = 0 
				end

				if fireCount ~= 0 and timeout == 0 then
					local fireWeaponHash = tostring(fireWeapon)
					local weaponName = WeaponNames[fireWeaponHash]
					
					if not weaponName then 
						TriggerServerEvent('fx-logs:shootinglogs', 'Undefined Weapon', fireCount)
						fireCount = 0
						goto continue
					end
					
					local isLoggedWeapon = true
					for _, weaponHash in ipairs(Config.WeaponsNotLogged) do
						if fireWeapon == GetHashKey(weaponHash) then
							isLoggedWeapon = false
							break
						end
					end
					
					if isLoggedWeapon then
						TriggerServerEvent('fx-logs:shootinglogs', weaponName, fireCount)
					end
					
					fireCount = 0
				end
			end
			::continue::
		end
	end)
end
-- [[ Damage logs. ]]
if Config.EnableLogs and Config.EnableLogs.Damage then
	Citizen.CreateThread(function()
		local health = nil
		local armor = nil
		local playerped = nil

		while true do
			Citizen.Wait(500)
			playerPed = PlayerPedId()

			if health == nil then 
				health = GetEntityHealth(playerPed) 
				armor = GetPedArmour(playerPed)
			end
			
			local currentHealth = GetEntityHealth(playerPed)
			local currentArmor = GetPedArmour(playerPed)
			
			if currentArmor < armor then
				local damageAmount = armor - currentArmor
				TriggerServerEvent('fx-logs:damagelogs', 'armor', damageAmount)
				armor = currentArmor
			elseif currentHealth < health then
				local damageAmount = health - currentHealth
				TriggerServerEvent('fx-logs:damagelogs', 'health', damageAmount)
				health = currentHealth
			end
			health = math.max(health, currentHealth)
			armor = math.max(armor, currentArmor)
		end
	end)
end

function IsMelee(Weapon)
	local Weapons = {'WEAPON_UNARMED', 'WEAPON_CROWBAR', 'WEAPON_BAT', 'WEAPON_GOLFCLUB', 'WEAPON_HAMMER', 'WEAPON_NIGHTSTICK'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsTorch(Weapon)
	local Weapons = {'WEAPON_MOLOTOV'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsKnife(Weapon)
	local Weapons = {'WEAPON_DAGGER', 'WEAPON_KNIFE', 'WEAPON_SWITCHBLADE', 'WEAPON_HATCHET', 'WEAPON_BOTTLE'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsPistol(Weapon)
	local Weapons = {'WEAPON_SNSPISTOL', 'WEAPON_HEAVYPISTOL', 'WEAPON_VINTAGEPISTOL', 'WEAPON_PISTOL', 'WEAPON_APPISTOL', 'WEAPON_COMBATPISTOL'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsSub(Weapon)
	local Weapons = {'WEAPON_MICROSMG', 'WEAPON_SMG'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsRifle(Weapon)
	local Weapons = {'WEAPON_CARBINERIFLE', 'WEAPON_MUSKET', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_ASSAULTRIFLE', 'WEAPON_SPECIALCARBINE', 'WEAPON_COMPACTRIFLE', 'WEAPON_BULLPUPRIFLE'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsLight(Weapon)
	local Weapons = {'WEAPON_MG', 'WEAPON_COMBATMG'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsShotgun(Weapon)
	local Weapons = {'WEAPON_BULLPUPSHOTGUN', 'WEAPON_ASSAULTSHOTGUN', 'WEAPON_DBSHOTGUN', 'WEAPON_PUMPSHOTGUN', 'WEAPON_HEAVYSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsSniper(Weapon)
	local Weapons = {'WEAPON_MARKSMANRIFLE', 'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_ASSAULTSNIPER', 'WEAPON_REMOTESNIPER'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsHeavy(Weapon)
	local Weapons = {'WEAPON_GRENADELAUNCHER', 'WEAPON_RPG', 'WEAPON_FLAREGUN', 'WEAPON_HOMINGLAUNCHER', 'WEAPON_FIREWORK', 'VEHICLE_WEAPON_TANK'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsMinigun(Weapon)
	local Weapons = {'WEAPON_MINIGUN'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsBomb(Weapon)
	local Weapons = {'WEAPON_GRENADE', 'WEAPON_PROXMINE', 'WEAPON_EXPLOSION', 'WEAPON_STICKYBOMB'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsVeh(Weapon)
	local Weapons = {'VEHICLE_WEAPON_ROTORS'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

function IsVK(Weapon)
	local Weapons = {'WEAPON_RUN_OVER_BY_CAR', 'WEAPON_RAMMED_BY_CAR'}
	for i, CurrentWeapon in ipairs(Weapons) do
		if GetHashKey(CurrentWeapon) == Weapon then
			return true
		end
	end
	return false
end

WeaponNames = {
	[tostring(GetHashKey('WEAPON_UNARMED'))] = 'Unarmed',
	[tostring(GetHashKey('WEAPON_KNIFE'))] = 'Knife',
	[tostring(GetHashKey('WEAPON_NIGHTSTICK'))] = 'Nightstick',
	[tostring(GetHashKey('WEAPON_HAMMER'))] = 'Hammer',
	[tostring(GetHashKey('WEAPON_BAT'))] = 'Baseball Bat',
	[tostring(GetHashKey('WEAPON_GOLFCLUB'))] = 'Golf Club',
	[tostring(GetHashKey('WEAPON_CROWBAR'))] = 'Crowbar',
	[tostring(GetHashKey('WEAPON_PISTOL'))] = 'Pistol',
	[tostring(GetHashKey('WEAPON_COMBATPISTOL'))] = 'Combat Pistol',
	[tostring(GetHashKey('WEAPON_APPISTOL'))] = 'AP Pistol',
	[tostring(GetHashKey('WEAPON_PISTOL50'))] = 'Pistol .50',
	[tostring(GetHashKey('WEAPON_MICROSMG'))] = 'Micro SMG',
	[tostring(GetHashKey('WEAPON_SMG'))] = 'SMG',
	[tostring(GetHashKey('WEAPON_ASSAULTSMG'))] = 'Assault SMG',
	[tostring(GetHashKey('WEAPON_ASSAULTRIFLE'))] = 'Assault Rifle',
	[tostring(GetHashKey('WEAPON_CARBINERIFLE'))] = 'Carbine Rifle',
	[tostring(GetHashKey('WEAPON_ADVANCEDRIFLE'))] = 'Advanced Rifle',
	[tostring(GetHashKey('WEAPON_MG'))] = 'MG',
	[tostring(GetHashKey('WEAPON_COMBATMG'))] = 'Combat MG',
	[tostring(GetHashKey('WEAPON_PUMPSHOTGUN'))] = 'Pump Shotgun',
	[tostring(GetHashKey('WEAPON_SAWNOFFSHOTGUN'))] = 'Sawed-Off Shotgun',
	[tostring(GetHashKey('WEAPON_ASSAULTSHOTGUN'))] = 'Assault Shotgun',
	[tostring(GetHashKey('WEAPON_BULLPUPSHOTGUN'))] = 'Bullpup Shotgun',
	[tostring(GetHashKey('WEAPON_STUNGUN'))] = 'Stun Gun',
	[tostring(GetHashKey('WEAPON_SNIPERRIFLE'))] = 'Sniper Rifle',
	[tostring(GetHashKey('WEAPON_HEAVYSNIPER'))] = 'Heavy Sniper',
	[tostring(GetHashKey('WEAPON_REMOTESNIPER'))] = 'Remote Sniper',
	[tostring(GetHashKey('WEAPON_GRENADELAUNCHER'))] = 'Grenade Launcher',
	[tostring(GetHashKey('WEAPON_GRENADELAUNCHER_SMOKE'))] = 'Smoke Grenade Launcher',
	[tostring(GetHashKey('WEAPON_RPG'))] = 'RPG',
	[tostring(GetHashKey('WEAPON_PASSENGER_ROCKET'))] = 'Passenger Rocket',
	[tostring(GetHashKey('WEAPON_AIRSTRIKE_ROCKET'))] = 'Airstrike Rocket',
	[tostring(GetHashKey('WEAPON_STINGER'))] = 'Stinger [Vehicle]',
	[tostring(GetHashKey('WEAPON_MINIGUN'))] = 'Minigun',
	[tostring(GetHashKey('WEAPON_GRENADE'))] = 'Grenade',
	[tostring(GetHashKey('WEAPON_STICKYBOMB'))] = 'Sticky Bomb',
	[tostring(GetHashKey('WEAPON_SMOKEGRENADE'))] = 'Tear Gas',
	[tostring(GetHashKey('WEAPON_BZGAS'))] = 'BZ Gas',
	[tostring(GetHashKey('WEAPON_MOLOTOV'))] = 'Molotov',
	[tostring(GetHashKey('WEAPON_FIREEXTINGUISHER'))] = 'Fire Extinguisher',
	[tostring(GetHashKey('WEAPON_PETROLCAN'))] = 'Jerry Can',
	[tostring(GetHashKey('OBJECT'))] = 'Object',
	[tostring(GetHashKey('WEAPON_BALL'))] = 'Ball',
	[tostring(GetHashKey('WEAPON_FLARE'))] = 'Flare',
	[tostring(GetHashKey('VEHICLE_WEAPON_TANK'))] = 'Tank Cannon',
	[tostring(GetHashKey('VEHICLE_WEAPON_SPACE_ROCKET'))] = 'Rockets',
	[tostring(GetHashKey('VEHICLE_WEAPON_PLAYER_LASER'))] = 'Laser',
	[tostring(GetHashKey('AMMO_RPG'))] = 'Rocket',
	[tostring(GetHashKey('AMMO_TANK'))] = 'Tank',
	[tostring(GetHashKey('AMMO_SPACE_ROCKET'))] = 'Rocket',
	[tostring(GetHashKey('AMMO_PLAYER_LASER'))] = 'Laser',
	[tostring(GetHashKey('AMMO_ENEMY_LASER'))] = 'Laser',
	[tostring(GetHashKey('WEAPON_RAMMED_BY_CAR'))] = 'Rammed by Car',
	[tostring(GetHashKey('WEAPON_BOTTLE'))] = 'Bottle',
	[tostring(GetHashKey('WEAPON_GUSENBERG'))] = 'Gusenberg Sweeper',
	[tostring(GetHashKey('WEAPON_SNSPISTOL'))] = 'SNS Pistol',
	[tostring(GetHashKey('WEAPON_VINTAGEPISTOL'))] = 'Vintage Pistol',
	[tostring(GetHashKey('WEAPON_DAGGER'))] = 'Antique Cavalry Dagger',
	[tostring(GetHashKey('WEAPON_FLAREGUN'))] = 'Flare Gun',
	[tostring(GetHashKey('WEAPON_HEAVYPISTOL'))] = 'Heavy Pistol',
	[tostring(GetHashKey('WEAPON_SPECIALCARBINE'))] = 'Special Carbine',
	[tostring(GetHashKey('WEAPON_MUSKET'))] = 'Musket',
	[tostring(GetHashKey('WEAPON_FIREWORK'))] = 'Firework Launcher',
	[tostring(GetHashKey('WEAPON_MARKSMANRIFLE'))] = 'Marksman Rifle',
	[tostring(GetHashKey('WEAPON_HEAVYSHOTGUN'))] = 'Heavy Shotgun',
	[tostring(GetHashKey('WEAPON_PROXMINE'))] = 'Proximity Mine',
	[tostring(GetHashKey('WEAPON_HOMINGLAUNCHER'))] = 'Homing Launcher',
	[tostring(GetHashKey('WEAPON_HATCHET'))] = 'Hatchet',
	[tostring(GetHashKey('WEAPON_COMBATPDW'))] = 'Combat PDW',
	[tostring(GetHashKey('WEAPON_KNUCKLE'))] = 'Knuckle Duster',
	[tostring(GetHashKey('WEAPON_MARKSMANPISTOL'))] = 'Marksman Pistol',
	[tostring(GetHashKey('WEAPON_MACHETE'))] = 'Machete',
	[tostring(GetHashKey('WEAPON_MACHINEPISTOL'))] = 'Machine Pistol',
	[tostring(GetHashKey('WEAPON_FLASHLIGHT'))] = 'Flashlight',
	[tostring(GetHashKey('WEAPON_DBSHOTGUN'))] = 'Double Barrel Shotgun',
	[tostring(GetHashKey('WEAPON_COMPACTRIFLE'))] = 'Compact Rifle',
	[tostring(GetHashKey('WEAPON_SWITCHBLADE'))] = 'Switchblade',
	[tostring(GetHashKey('WEAPON_REVOLVER'))] = 'Heavy Revolver',
	[tostring(GetHashKey('WEAPON_FIRE'))] = 'Fire',
	[tostring(GetHashKey('WEAPON_HELI_CRASH'))] = 'Heli Crash',
	[tostring(GetHashKey('WEAPON_RUN_OVER_BY_CAR'))] = 'Run over by Car',
	[tostring(GetHashKey('WEAPON_HIT_BY_WATER_CANNON'))] = 'Hit by Water Cannon',
	[tostring(GetHashKey('WEAPON_EXHAUSTION'))] = 'Exhaustion',
	[tostring(GetHashKey('WEAPON_EXPLOSION'))] = 'Explosion',
	[tostring(GetHashKey('WEAPON_ELECTRIC_FENCE'))] = 'Electric Fence',
	[tostring(GetHashKey('WEAPON_BLEEDING'))] = 'Bleeding',
	[tostring(GetHashKey('WEAPON_DROWNING_IN_VEHICLE'))] = 'Drowning in Vehicle',
	[tostring(GetHashKey('WEAPON_DROWNING'))] = 'Drowning',
	[tostring(GetHashKey('WEAPON_BARBED_WIRE'))] = 'Barbed Wire',
	[tostring(GetHashKey('WEAPON_VEHICLE_ROCKET'))] = 'Vehicle Rocket',
	[tostring(GetHashKey('WEAPON_BULLPUPRIFLE'))] = 'Bullpup Rifle',
	[tostring(GetHashKey('WEAPON_ASSAULTSNIPER'))] = 'Assault Sniper',
	[tostring(GetHashKey('VEHICLE_WEAPON_ROTORS'))] = 'Rotors',
	[tostring(GetHashKey('WEAPON_RAILGUN'))] = 'Railgun',
	[tostring(GetHashKey('WEAPON_AIR_DEFENCE_GUN'))] = 'Air Defence Gun',
	[tostring(GetHashKey('WEAPON_AUTOSHOTGUN'))] = 'Automatic Shotgun',
	[tostring(GetHashKey('WEAPON_BATTLEAXE'))] = 'Battle Axe',
	[tostring(GetHashKey('WEAPON_COMPACTLAUNCHER'))] = 'Compact Grenade Launcher',
	[tostring(GetHashKey('WEAPON_MINISMG'))] = 'Mini SMG',
	[tostring(GetHashKey('WEAPON_PIPEBOMB'))] = 'Pipebomb',
	[tostring(GetHashKey('WEAPON_POOLCUE'))] = 'Poolcue',
	[tostring(GetHashKey('WEAPON_WRENCH'))] = 'Wrench',
	[tostring(GetHashKey('WEAPON_SNOWBALL'))] = 'Snowball',
	[tostring(GetHashKey('WEAPON_ANIMAL'))] = 'Animal',
	[tostring(GetHashKey('WEAPON_COUGAR'))] = 'Cougar',
    [tostring(GetHashKey('WEAPON_AKG'))] = 'AKG',
    [tostring(GetHashKey('WEAPON_FOOL'))] = 'FOOL',
    [tostring(GetHashKey('WEAPON_T9ACC'))] = 'T9ACC',
    [tostring(GetHashKey('WEAPON_STG'))] = 'STG',
    [tostring(GetHashKey('WEAPON_MDR'))] = 'MDR',
    [tostring(GetHashKey('WEAPON_FNFAL'))] = 'FNFAL',
    [tostring(GetHashKey('WEAPON_M4A4'))] = 'M4A4',
    [tostring(GetHashKey('WEAPON_BEOWULF'))] = 'BEOWUFL',
    [tostring(GetHashKey('WEAPON_ACR'))] = 'ACR',
    [tostring(GetHashKey('WEAPON_HK516'))] = 'HK516',
    [tostring(GetHashKey('WEAPON_MPX'))] = 'MPX',
    [tostring(GetHashKey('WEAPON_FAMAS'))] = 'FAMAS',
    [tostring(GetHashKey('WEAPON_CBQ'))] = 'CBQ',
    [tostring(GetHashKey('WEAPON_BIZON'))] = 'BIZON',
    [tostring(GetHashKey('WEAPON_BARSKA'))] = 'BARSKA',
    [tostring(GetHashKey('WEAPON_AUG'))] = 'AUG',
    [tostring(GetHashKey('WEAPON_AK102'))] = 'AK-102',
    [tostring(GetHashKey('WEAPON_AK12'))] = 'AK-12',
    [tostring(GetHashKey('WEAPON_AUGA'))] = 'AUGA',
    [tostring(GetHashKey('WEAPON_M16A1'))] = 'M16A1',
    [tostring(GetHashKey('WEAPON_SCARMK17'))] = 'SCARMK-17',
    [tostring(GetHashKey('WEAPON_M203'))] = 'M203',
    [tostring(GetHashKey('WEAPON_ISY'))] = 'ISY',
    [tostring(GetHashKey('WEAPON_REDISY'))] = 'FIRED ISY',
    [tostring(GetHashKey('WEAPON_MARINE'))] = 'MARINE',
    [tostring(GetHashKey('WEAPON_L119A2'))] = 'L119A2',
    [tostring(GetHashKey('WEAPON_AK117'))] = 'AK-117',
    [tostring(GetHashKey('WEAPON_MINIAK'))] = 'MINIAK',
    [tostring(GetHashKey('WEAPON_G36K'))] = 'G36K',
    [tostring(GetHashKey('WEAPON_MILITERYSMG'))] = 'Military SMG',
    [tostring(GetHashKey('WEAPON_M13'))] = 'M133',
    [tostring(GetHashKey('WEAPON_AKM'))] = 'AKM',
    [tostring(GetHashKey('WEAPON_G36C'))] = 'G36C',
    [tostring(GetHashKey('WEAPON_RPK'))] = 'RPK',
    [tostring(GetHashKey('WEAPON_SUNDA2'))] = 'SUNDA2',
    [tostring(GetHashKey('WEAPON_SUNDA'))] = 'SUNDA',
    [tostring(GetHashKey('WEAPON_SAKURA'))] = 'SAKURA',
    [tostring(GetHashKey('WEAPON_GRAU'))] = 'GRAU',
    [tostring(GetHashKey('WEAPON_M4A5'))] = 'M4A5',
    [tostring(GetHashKey('WEAPON_HK43'))] = 'HK43',
    [tostring(GetHashKey('WEAPON_HK416'))] = 'HK416',
    [tostring(GetHashKey('WEAPON_SIG516'))] = 'SIG516',
    [tostring(GetHashKey('WEAPON_DRAGON'))] = 'DRAGON',
    [tostring(GetHashKey('WEAPON_CZ75'))] = 'CZ75',
    [tostring(GetHashKey('WEAPON_FENNEC'))] = 'FENNEC',
    [tostring(GetHashKey('WEAPON_MAC10'))] = 'MAC10',
    [tostring(GetHashKey('WEAPON_PHANTOM'))] = 'PHANTOM',
    [tostring(GetHashKey('WEAPON_MP40'))] = 'MP40',
    [tostring(GetHashKey('WEAPON_BTR'))] = 'BTR',
    [tostring(GetHashKey('WEAPON_IA2'))] = 'IA2',
    [tostring(GetHashKey('WEAPON_M4A8'))] = 'M4A8',
    [tostring(GetHashKey('WEAPON_SCAR'))] = 'SCAR',
    [tostring(GetHashKey('WEAPON_VECTOR45'))] = 'VECTOR45',
    [tostring(GetHashKey('WEAPON_P90'))] = 'P90',
    [tostring(GetHashKey('WEAPON_TAR'))] = 'TAR',
	[tostring(GetHashKey('WEAPON_KTR'))] = 'KTR',
    [tostring(GetHashKey('WEAPON_M4'))] = 'M4',
    [tostring(GetHashKey('WEAPON_RTD'))] = 'RTD',
    [tostring(GetHashKey('WEAPON_AR15'))] = 'AR15',
}