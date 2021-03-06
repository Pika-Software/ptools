Msg"MDL RePatherV3 by Klen_list\n"
file.CreateDir"mdlrepath"

local nullchar = "\x00"

local function ReadStrNullEsc(file_class) -- reading str until current char not a 0x0
    local out, char = ""
    while char ~= nullchar do
        char = file_class:Read(1)
        out = out .. char
    end
    return out
end

local function RePath(mdlpath, new_paths)
    MsgN("Staring repath for ", mdlpath)

    local newfilepath = "mdlrepath/" .. string.Replace(string.GetFileFromFilename(mdlpath), ".mdl", "") .. ".txt"
    file.Write(newfilepath, "")

    local r = file.Open(mdlpath, "rb", "GAME")
    local w = file.Open(newfilepath, "wb", "DATA")

    w:Write(r:Read(76))
    w:WriteULong(0) r:Skip(4) -- skip file size, write it later
    w:Write(r:Read(132))

    local count = r:ReadULong()
    MsgN("Old count: ", count)
    MsgN("New count: ", #new_paths)
    w:WriteULong(#new_paths) -- write new cdpath count
    local offset = r:ReadULong()
    w:WriteULong(offset) -- safe offset to series of ints

    w:Write(r:Read(offset - r:Tell()))

    local path_offsets = {}
    local base_offset = math.huge
    for i = 1,count do
        local offs = r:ReadULong()
        path_offsets[offs] = true
        base_offset = math.min(base_offset, offs)
        w:WriteULong(0)
    end

    MsgN("Base offset: ", base_offset)

   -- w:Write(r:Read(base_offset - r:Tell()))

    MsgN"Old cdmaterials:"

    local keys = table.GetKeys(path_offsets)
    table.sort(keys, function(a, b) return a < b end)

    for i = 1, #keys do -- write to the end, ignore old cdmath data
        local offs = keys[i]
        print(offs)
        w:Write(r:Read(offs - r:Tell()))
        MsgN(" >", ReadStrNullEsc(r))
        w:WriteByte(0)
        if i == #keys then
            for j,newpath in ipairs(new_paths) do
                local cur = w:Tell()
                w:Seek(offset + (j - 1) * 4)
                w:WriteULong(cur) -- write new offsets in series of int
                w:Seek(cur)
                w:Write(newpath)
                w:WriteByte(0)
            end
        end
    end

    w:Write(r:Read(r:Size() - r:Tell()))

    local newsize = w:Tell()
    w:Seek(76)
    w:WriteULong(newsize)

    r:Close()
    w:Close()
    r, w = nil, nil
    Msg"Repathing complited!\n"
end

-- Example
RePath("models/player/lappland/lappland_arms.mdl", {[[models\player\lappland\]]})