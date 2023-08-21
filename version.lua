Citizen.CreateThread(function()
    local resource = GetCurrentResourceName()
    local versionFile = LoadResourceFile(resource, 'version.txt')
    if versionFile then
        print('^2version.txt File correctly initialized!^7') 
        PerformHttpRequest("https://raw.githubusercontent.com/rocket5115/SSC-remastered/main/version.txt", function (errorCode, resultData, resultHeaders)
            if errorCode == 200 then
                local ovf = versionFile
                local ord = resultData
                versionFile = versionFile:gsub('[%. ]', '') -- Remove spaces and periods
                resultData = resultData:gsub('[%. ]', '') -- Remove spaces and periods
                
                local vNum = tonumber(versionFile)
                local rNum = tonumber(resultData)
                if vNum == rNum then
                    print('^2You have up to date version of Simple Scene Creator: '..ovf..'^7')
                elseif vNum>rNum then
                    print('^1You seem to have higher version of Simple Scene Creator. \nOwned: '..ovf..'\nCurrent: '..ord..'\nIt\'s recommended to check if your version is the correct one.^7')
                else
                    print('^1You don\'t have the latest version of Simple Scene Creator!\nOwned: '..ovf..'\nCurrent: '..ord..'\nIt\'s recommended to download the newest version as it contains many more features and less known bugs.^7')
                end
            else
                print('^1Version check failed!^7')
            end
        end)
    else
        print('^1version.txt not Found! Version check failed, please make sure you have the latest available version.^7')
        SaveResourceFile(resource, '/json/version.json', '1.0.0', -1)
    end
end)