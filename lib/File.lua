local File = class()

function File:create(path)
    local self = {
        path = path
    }

    setmetatable(self, File)

    return self
end

function File:__tostring()
    return self.path
end

function File:exists()
    return reaper.file_exists(self.path)
end

function File:setContent(data)
    writeFile(self.path, data)
    return file
end

function File:getContent()
    return readFile(self.path)
end


return File