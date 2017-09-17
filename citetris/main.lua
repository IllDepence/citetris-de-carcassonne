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
    if self.xPos == 210 and self.yPos == 0 then
        gameState = 'over'
        return
    end

    self.active = false
    table.insert(deadTiles, self)
    score = score + speed

    si = posToSlotIndex(self.xPos, self.yPos)
    i = si['i']
    j = si['j']

    -- check placement validity
    srl = getSlotRestrictionList()
    restr = srl[i]
    edges = tileEdges[self.id] -- non rotated full edges
    round = edges .. edges:sub(1,3) -- allow offset indexing
    rot = self.rotation
    actualEdges = round:sub(1+rot, 4+rot) -- actual edges w/o top
    valid = true
    for i = 1, 3 do
        if not (restr:sub(i,i) == '-') then
            if not (restr:sub(i,i) == actualEdges:sub(i,i)) then
                valid = false
            end
        end
    end
    if not valid then
        gameState = 'over'
        return
    end

    -- update slotRestrictions
    -- self
    slotRestrictions[i][j] = 'xxx'
    -- left neighbour
    if i > 1 and not (slotRestrictions[i-1][j] == 'xxx') then
        pre = slotRestrictions[i-1][j]
        ins = actualEdges:sub(1,1)
        slotRestrictions[i-1][j] = pre:sub(1,2) .. ins
    end
    -- right neighbour
    if i < 5 and not (slotRestrictions[i+1][j] == 'xxx') then
        pre = slotRestrictions[i+1][j]
        ins = actualEdges:sub(3,3)
        slotRestrictions[i+1][j] = ins .. pre:sub(2,3)
    end
    -- top neighbour
    if j < 8 then
        pre = slotRestrictions[i][j+1]
        ins = actualEdges:sub(4,4)
        slotRestrictions[i][j+1] = pre:sub(1,1) .. ins .. pre:sub(3,3)
    end
    -- printSlotRestrictions()

    clearRows()
    spawnNewTile()
end

function clearRows()
    rowDone = true
    for i = 1, 5 do
        if not (slotRestrictions[i][2] == 'xxx') then
            rowDone = false
        end
    end
    if rowDone then
        score = 10 * speed
        for i = 1, 5 do
            table.remove(slotRestrictions[i], 1)
            slotRestrictions[i][8] = '---'
        end
        newDeadTiles = {}
        for k, tile in pairs(deadTiles) do
            if not(tile.yPos == 700) then
                tile.yPos = tile.yPos + 100
                table.insert(newDeadTiles, tile)
            end
            deadTiles = newDeadTiles
        end
    end
end

function getSlotRestrictionList()
    ret = {}
    for i = 1, 5 do
        done = false
        for j = 1, 8 do
            if not (slotRestrictions[i][j] == 'xxx')  and not done then
                table.insert(ret, slotRestrictions[i][j])
                done = true
            end
        end
    end
    return ret
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

function spawnNewTile(srl)
    srl = getSlotRestrictionList()
    placeableTileIDs = {}
    for k, edges in pairs(tileEdges) do
        placeable = false
        check = edges .. edges:sub(1,2)
        for l, restr in pairs(srl) do
            if not placeable then
                restr = string.gsub(restr, '-', '')
                if string.match(check, restr) then
                    table.insert(placeableTileIDs, k)
                    placeable = true
                end
            end
        end
    end
    lim = table.getn(placeableTileIDs)
    activeTile = Tile:new(placeableTileIDs[math.random(lim)])
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

gameState = 'running'
tileImgs = {}
tileIDs = {'a', 'b', 'c', 'd', 'e', 'fg', 'h', 'i', 'j', 'k', 'l', 'mn', 'op',
           'qr', 'st', 'u', 'v', 'w', 'x'}
tileEdges = {a ='gggg',
             b ='grgg',
             c ='cccc',
             d ='rgrc',
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
score = 0
-- ### /global

-- ### callback functions

function love.load()
    love.window.setTitle('Citétris de Carcassonne')
    love.window.setMode(600, 810, {})
    latoFont24 = love.graphics.newFont('assets/Lato-Light.ttf', 24)
    bg = love.graphics.newImage('assets/bg.png')
    game_over = love.graphics.newImage('assets/game_over.png')

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
    if gameState == 'running' then
        interval = interval - dt
        if interval <= 0 then
            activeTile:goDown()
            interval = resetInterval()
        end
    end
end

function love.draw()
    love.graphics.setFont(latoFont24)
    love.graphics.draw(bg, 0, 0)
    activeTile:draw()
    for k, tile in pairs(deadTiles) do
        tile:draw()
    end

    love.graphics.setColor(85, 34, 0, 255)
    love.graphics.print('SCORE', 516, 50)
    love.graphics.print(string.format('%05d', score), 516, 77)
    love.graphics.print('SPEED', 516, 120)
    love.graphics.print(string.format('%05d', speed), 516, 147)
    love.graphics.setColor(255, 255, 255, 255)

    if gameState == 'over' then
        love.graphics.draw(game_over, 0, 0)
    end
end

function love.keypressed(key, scancode)
    if scancode ~= nil then
        if scancode == 'up' then
            activeTile:rotate()
        elseif scancode == 'down' then
            activeTile:goDown()
        elseif scancode == 'right' then
            activeTile:goRight()
        elseif scancode == 'left' then
            activeTile:goLeft()
        elseif scancode == 'space' then
            activeTile:goBottom()
        elseif scancode == 'p' then
            if gameState == 'running' then
                gameState = 'paused'
            end
        end
    end
end

-- ###/ callback functions
