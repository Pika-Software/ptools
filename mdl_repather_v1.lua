print"MDL RePatcher by Klen_list"
file.CreateDir"mdlrepath"

local function RePath(mdlpath, newmatpath)
    print("Staring repath for ", mdlpath)

    local newfilepath = "mdlrepath/" .. string.Replace(string.GetFileFromFilename(mdlpath), ".mdl", "") .. ".txt"
    file.Write(newfilepath, "")

    local r = file.Open(mdlpath, "rb", "GAME")
    local w = file.Open(newfilepath, "wb", "DATA")

    r:Skip(4) -- Model format ID
    w:Write"IDST"

    local version = r:ReadULong() -- Format version number, default 48
    print("MDL Version: ", version)
    w:WriteULong(version)

    local checksum = r:ReadULong() -- Same in the .phy and .vtx
    print("MDL CheckSum: ", checksum)
    w:WriteULong(checksum)

    local name = r:Read(64) -- Internal name of the model
    print("MDL Name: ", name)
    w:Write(name)

    local size = r:ReadULong() -- Size of .mdl file
    print("Original size: ", size)

    -- Let-s update material path

    local data = string.reverse(r:Read(r:Size() - r:Tell()))
    local orig_path = ""
    local pathend_pos = 0
    for i = 5,#data do -- Skip 4 bytes of padding
        local _char = string.sub(data, i, i)
        if _char:byte() == 0 then
            pathend_pos = i
            break
        end
        orig_path = orig_path .. _char
    end
    orig_path = string.reverse(orig_path)
    print("Original material path: ", orig_path)

    print"Constructing data.."
    local new_data = "\x00\x00\x00\x00" .. string.reverse(newmatpath) .. data:sub(pathend_pos)
    local newsize = #new_data + 80

    print("MDL New Size: ", newsize)
    w:WriteULong(newsize)

    print"Writing new MDL Data.."
    w:Write(string.reverse(new_data))

    r:Close()
    w:Close()
    r, w = nil, nil
    print"Repathing complited!"
end

-- Example
RePath("models/electrification/generator.mdl", [[models\craftsys\gen\]])