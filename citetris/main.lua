Tile = {}

function Tile:new(id)
    o = {}
    setmetatable(o, {__index = Tile})
    o.id = id
    o.w = 100
    o.h = 100
    o.xPos = 10
    o.yPos = 0
    o.rotation = 0
    o.active = true
    return o
end

function Tile:draw()
    img = tileImgs[self.id]
    x = self.xPos
    y = self.yPos
    rot = math.rad(90 * self.rotation)
    if self.rotation == 1 then
        x = x + 100
    end
    if self.rotation == 2 then
        x = x + 100
        y = y + 100
    end
    if self.rotation == 3 then
        y = y + 100
    end
    love.graphics.draw(img, x, y, rot)
end

function Tile:minX()
    return self.xPos
end

function Tile:maxX()
    return self.xPos + self.w
end

function Tile:minY()
    return self.yPos
end

function Tile:maxY()
    return self.yPos + self.h
end

function Tile:rotate()
    self.rotation = (self.rotation + 1) % 4
end

function Tile:goDown()
    if not isTaken(self.xPos, self.yPos + 100) then
        self.yPos = self.yPos + 100
        return true
    else
        self:die()
        return false
    end
end

function Tile:goRight()
    if not isTaken(self.xPos + 100, self.yPos) then
        self.xPos = self.xPos + 100
    end
end

function Tile:goLeft()
    if not isTaken(self.xPos - 100, self.yPos) then
        self.xPos = self.xPos - 100
    end
end

function Tile:goBottom()
    moved = true
    while moved do
        moved = self:goDown()
    end
end

function Tile:die()
    self.active = false
    table.insert(deadTiles, self)
    spawnNewTile()
end

function isTaken(x, y)
    if x < 10 or x > 410 or y > 700 then
        return true
    end
    for k, tile in pairs(deadTiles) do
        if tile.xPos == x and tile.yPos == y then
            return true
        end
    end
    return false
end

function resetInterval()
    return 1/speed
end

function spawnNewTile()
    activeTile = Tile:new('w')
end

-- ### globals
tileImgs = {}
activeTile = Tile:new('d')
deadTiles = {}
speed = 1
interval = 0
-- ### /globals

-- ### callback functions

function love.load()
    love.window.setTitle("Citétris de Carcassonne")
    love.window.setMode(600, 810, {})
    bg = love.graphics.newImage('assets/bg.png')

    -- load tile imgs
    tileIDs = {'a', 'b', 'c', 'd', 'e', 'fg', 'h', 'i', 'j', 'k', 'l', 'mn',
               'op', 'qr', 'st', 'u', 'v', 'w', 'x'}
    for i = 1, 19 do
        id = tileIDs[i]
        tileImgs[id] = love.graphics.newImage('assets/tile_' .. id .. '.png')
    end

    -- game setup
    interval = resetInterval()
end

function love.update(dt)
    interval = interval - dt
    if interval <= 0 then
        activeTile:goDown()
        interval = resetInterval()
    end
end

function love.draw()
    love.graphics.draw(bg, 0, 0)
    activeTile:draw()
    for k, tile in pairs(deadTiles) do
        tile:draw()
    end
end

function love.keypressed(key, scancode)
    if scancode ~= nil then
        if scancode == "up" then
            activeTile:rotate()
        elseif scancode == "down" then
            activeTile:goDown()
        elseif scancode == "right" then
            activeTile:goRight()
        elseif scancode == "left" then
            activeTile:goLeft()
        elseif scancode == "space" then
            activeTile:goBottom()
        end
    end
end

-- ###/ callback functions
