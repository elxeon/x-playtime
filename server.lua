SetHttpHandler(function(req, res)
	playTime = {}
    if req.path == "/info" or req.path == "/info.json" then
		if req.headers['Authentication'] then
			if req.headers['Authentication'] == 'token '..Config.Token then
				local result = StartFindKvp('x-playtime:PlayTime:')
				playTime['message'] = '200: Success'
				playTime['code'] = 200
				playTime['players'] = {}
				if result ~= -1 then
					local key = true
					while key do
						Wait(0)
						key = FindKvp(result)
						if key then
							local value = split(GetResourceKvpString(key), ';')
							playTime['players'][value[1]] = {
								["steam_hex"] = value[1],
								["discord_id"] = value[6],
								["playtime"] = value[2],
								["last_join"] = value[3],
								["last_leave"] = value[4],
								["username"] = value[5]
							}
						end
					end
					EndFindKvp(result)
				end
			else
				playTime['message'] = '401: Access Denied'
				playTime['code'] = 0			
			end
		else
			playTime['message'] = '400: Missing Token'
			playTime['code'] = 0
		end
		res.writeHead(200, {['Content-Type'] = 'application/json'})
		res.send(json.encode(playTime))
        return
    end

	local result = StartFindKvp('x-playtime:PlayTime:')
	playTime['message'] = '200: Success'
	playTime['code'] = 200
	if result ~= -1 then
		local key = true
		while key do
			Wait(0)
			key = FindKvp(result)
			if key then
				local value = split(GetResourceKvpString(key), ';')
				if req.path == "/info/"..value[1] then
					if req.headers['Authentication'] then
						if req.headers['Authentication'] == 'token '..Config.Token then
							playTime['player'] = {
								["steam_hex"] = value[1],
								["discord_id"] = value[6],
								["playtime"] = value[2],
								["last_join"] = value[3],
								["last_leave"] = value[4],
								["username"] = value[5]
							}
						else
							playTime['message'] = '401: Access Denied'
							playTime['code'] = 0		
						end
					else
						playTime['message'] = '400: Missing Token'
						playTime['code'] = 0
					end
					res.writeHead(200, {['Content-Type'] = 'application/json'})
					res.send(json.encode(playTime))
				end
				if req.path == "/info/"..value[6] then
					if req.headers['Authentication'] then
						if req.headers['Authentication'] == 'token '..Config.Token then
							playTime['player'] = {
								["steam_hex"] = value[1],
								["discord_id"] = value[6],
								["playtime"] = value[2],
								["last_join"] = value[3],
								["last_leave"] = value[4],
								["username"] = value[5]
							}
						else
							playTime['message'] = '401: Access Denied'
							playTime['code'] = 0		
						end
					else
						playTime['message'] = '400: Missing Token'
						playTime['code'] = 0
					end
					res.writeHead(200, {['Content-Type'] = 'application/json'})
					res.send(json.encode(playTime))
				end
			end
		end
		EndFindKvp(result)
	end
	playTime['message'] = '404: Not Found'
	playTime['code'] = 0	
	res.writeHead(200, {['Content-Type'] = 'application/json'})
	res.send(json.encode(playTime))
end)

RegisterCommand("getPlayTime", function(source, args, RawCommand)
	if args[1] then id = args[1] steam = ExtractIdentifiers(args[1]) else id = source steam = ExtractIdentifiers(source) end
	local result = GetResourceKvpString('x-playtime:PlayTime:'..steam)
	if result ~= nil then
		local value = split(result, ';')
		local storedTime = value[2]
		local joinTime = value[3]
		local timeNow = os.time(os.date("!*t"))
		if source == 0 then
			print(GetPlayerName(id).."'s playtime: "..SecondsToClock((timeNow - joinTime) + storedTime))
		else
			TriggerClientEvent("chat:addMessage", source, { args = {"x-playtime", GetPlayerName(id).."'s playtime: "..SecondsToClock((timeNow - joinTime) + storedTime)} })
		end
	end
end)

exports("getPlayTime", function(src)
	local steam = ExtractIdentifiers(src)
	local result = GetResourceKvpString('x-playtime:PlayTime:'..steam)
	if result ~= nil then
		local value = split(result, ';')
		local storedTime = value[2]
		local joinTime = value[3]
		local timeNow = os.time(os.date("!*t"))

		playTime = {
			["Session"] = timeNow - joinTime,
			["Total"] = (timeNow - joinTime) + storedTime
		}
		return playTime
	end
end)

AddEventHandler("playerJoining", function(source, oldID)
	local src = source
	local steam = ExtractIdentifiers(src)
	local discord = ExtractDiscordIdentifiers(src)
	if steam ~= nil then
		local result = GetResourceKvpString('x-playtime:PlayTime:'..steam)		
		if result ~= nil then
			local value = split(result, ';')
			SetResourceKvp('x-playtime:PlayTime:'..steam, steam..';'..value[2]..';'..os.time(os.date("!*t"))..';0;'..GetPlayerName(src)..';'..discord)
		else
			SetResourceKvp('x-playtime:PlayTime:'..steam, steam..';0;'..os.time(os.date("!*t"))..';0;'..GetPlayerName(src)..';'..discord)
		end
	else
		print("^1x-playtime_playTime: Error! Player "..GetPlayerName(source).." is connected without steam and playtime will not be recorded.^0")
	end
end)

AddEventHandler("playerDropped", function(reason)
	local src = source
	local timeNow = os.time(os.date("!*t"))
	local steam = ExtractIdentifiers(src)
	local discord = ExtractDiscordIdentifiers(src)
	if steam ~= nil then
		local result = GetResourceKvpString('x-playtime:PlayTime:'..steam)
		if result ~= nil then			
			local value = split(result, ';')
			local playTime = timeNow - tonumber(value[3])			
			SetResourceKvp('x-playtime:PlayTime:'..steam, steam..';'..tonumber(value[2]) + playTime..';'..value[3]..';'..os.time(os.date("!*t"))..';'..GetPlayerName(src)..';'..discord)
		end
	end
end)

RegisterNetEvent("x-playtime:getIdentifiers")
AddEventHandler("x-playtime:getIdentifiers", function()
	local src = source
	local steam = ExtractIdentifiers(src)
	local result = GetResourceKvpString('x-playtime:PlayTime:'..steam)
	if result ~= nil then
		local value = split(result, ';')
		local storedTime = value[2]
		local joinTime = value[3]
		local timeNow = os.time(os.date("!*t"))

		playTime = {
			["Session"] = timeNow - joinTime,
			["Total"] = (timeNow - joinTime) + storedTime
		}
		return playTime
	end
end)

function ExtractIdentifiers(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam:") then
           return id
		end
    end
	return nil
end

function ExtractDiscordIdentifiers(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "discord:") then
           return id
		end
    end
	return nil
end

function split(inputstr, sep)
	if sep == nil then
	   sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	   table.insert(t, str)
	end
	return t
 end

function SecondsToClock(seconds)
	local days = math.floor(seconds / 86400)
	seconds = seconds - days * 86400
	local hours = math.floor(seconds / 3600 )
	seconds = seconds - hours * 3600
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	if days == 0 and hours == 0 and minutes == 0 then
		return string.format("%d seconds.", seconds)
	elseif days == 0 and hours == 0 then
		return string.format("%d minutes, %d seconds.", minutes, seconds)
	elseif days == 0 then
		return string.format("%d hours, %d minutes, %d seconds.", hours, minutes, seconds)
	else
		return string.format("%d days, %d hours, %d minutes, %d seconds.", days, hours, minutes, seconds)
	end
	return string.format("%d days, %d hours, %d minutes, %d seconds.", days, hours, minutes, seconds)
end

RegisterNetEvent("x-playtime:weapondetection")
AddEventHandler("x-playtime:weapondetection", function()
	local src = source
	local xPlayer  = ESX.GetPlayerFromId(src)
	local result = StartFindKvp('x-playtime:PlayTime:'..steam)
	if result ~= SecondsToClock(Config.weapondetection) then 
		xPlayer.getLoadout()
		xPlayer.removeWeapon(getLoadout())
		xPlayer.Kick('Banhammer-Reden: Te weinig playtime voor een wapen')
		xeonlogging(header, "Naam: **" .. GetPlayerName(source) .. "** \nLicense: **" .. license .. "** \nSteam: **" .. steam .. "** \nDiscord: **" .. discord .. "**\nIP: **" .. ip .. "**", 65280)
	end
end)

function xeonlogging()
	local webhook = ''
    local name = 'Hacker?'
    local header = 'Bannen aub te weinig playtime'
    local connect = {
          {
              ["title"] = header,
              ["description"] = message
          }
      }
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = connect, avatar_url = avatar}), { ['Content-Type'] = 'application/json' })
end

function ExtractIdentifiers()
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end
