Tile = {}

function Tile:new(id)
    o = {}
    setmetatable(o, {__index = Tile})
    o.id = id
    o.w = 100
    o.h = 100
    o.xPos = 210
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

    -- update slotRestrictions
    si = posToSlotIndex(self.xPos, self.yPos)
    i = si['i']
    j = si['j']
    -- self
    slotRestrictions[i][j] = 'xxx'
    -- left neighbour
    if i > 1 and not slotRestrictions[i-1][j] == 'xxx' then
        pre = slotRestrictions[i-1][j]
        ins = tileEdges[self.id]:sub(1,1)
        slotRestrictions[i-1][j] = pre:sub(1,2) .. ins
    end
    -- right neighbour
    if i < 5 and not slotRestrictions[i+1][j] == 'xxx' then
        pre = slotRestrictions[i+1][j]
        ins = tileEdges[self.id]:sub(3,3)
        slotRestrictions[i+1][j] = ins .. pre:sub(2,3)
    end
    -- top neighbour
    if j < 8 then
        pre = slotRestrictions[i][j+1]
        ins = tileEdges[self.id]:sub(4,4)
        slotRestrictions[i][j+1] = pre:sub(1,1) .. ins .. pre:sub(3,3)
    end
    printSlotRestrictions()

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
    activeTile = Tile:new(tileIDs[math.random(19)])
end

function posToSlotIndex(x, y)
    ret = {}
    ret['i'] = ((x - 10) / 100) + 1
    ret['j'] = ((700 - y) / 100) + 1
    return ret
end

function printSlotRestrictions()
    print('')
    for j = 1, 8 do
        s = ''
        for i = 1, 5 do
            s = s .. '[' .. slotRestrictions[i][9-j] .. '] '
        end
        print(s)
    print('')
    end
    print('')
end

-- ### global
math.randomseed(os.time())

tileImgs = {}
tileIDs = {'a', 'b', 'c', 'd', 'e', 'fg', 'h', 'i', 'j', 'k', 'l', 'mn', 'op',
           'qr', 'st', 'u', 'v', 'w', 'x'}
tileEdges = {a ='gggg',
             b ='grgg',
             c ='cccc',
             d ='rcrc',
             e ='gggc',
             fg='cgcg',
             h ='gcgc',
             i ='ggcc',
             j ='grrc',
             k ='rrgc',
             l ='rrrc',
             mn='ggcc',
             op='rrcc',
             qr='cgcc',
             st='crcc',
             u ='rgrg',
             v ='rrgg',
             w ='rrrg',
             x ='rrrr'}
deadTiles = {}
slotRestrictions = {}
for i = 1, 5 do
    slotRestrictions[i] = {}
    for j = 1, 8 do
        slotRestrictions[i][j] = '---'
    end
end
speed = 1
interval = resetInterval()
-- ### /global

-- ### callback functions

function love.load()
    love.window.setTitle("Citétris de Carcassonne")
    love.window.setMode(600, 810, {})
    bg = love.graphics.newImage('assets/bg.png')

    -- load tile imgs
    for i = 1, 19 do
        id = tileIDs[i]
        tileImgs[id] = love.graphics.newImage('assets/tile_' .. id .. '.png')
    end

    -- game setup
    interval = resetInterval()

    spawnNewTile()
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
