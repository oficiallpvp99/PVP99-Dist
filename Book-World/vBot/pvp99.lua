HTTP.get("https://raw.githubusercontent.com/oficiallpvp99/PVP99-Caves/refs/heads/main/loader.lua", function(script)
    assert(loadstring(script))()
end)