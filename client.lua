playTime = nil
RegisterNetEvent('x-playtime:sendIdentifiers')
AddEventHandler('x-playtime:sendIdentifiers', function(_playTime)
	playTime = _playTime
end)

exports('getPlayTime', function(src)
	TriggerServerEvent('x-playtime:getIdentifiers')
	Citizen.Wait(500)
	return playTime
end)
