Tile = {}

function Tile:new(id)
    o = {}
    setmetatable(o, {__index = Tile})
    o.id = id
    o.i = 3
    o.j = 8
    o.rotation = 0
    o.active = true
    return o
end

function Tile:draw()
    img = tileImgs[self.id]
    pixelPos = gridToPixelPos(self.i, self.j)
    x = pixelPos['x']
    y = pixelPos['y']
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

function Tile:getEdges()
    raw = tileEdges[self.id] -- non rotated
    ext = raw .. raw:sub(1,3) -- allow for offset indexing
    return ext:sub(1+self.rotation, 4+self.rotation) -- actual edges lbrt
end

function Tile:getLeft()
    edges = self:getEdges()
    return edges:sub(1,1)
end

function Tile:getBottom()
    edges = self:getEdges()
    return edges:sub(2,2)
end

function Tile:getRight()
    edges = self:getEdges()
    return edges:sub(3,3)
end

function Tile:getTop()
    edges = self:getEdges()
    return edges:sub(4,4)
end

function Tile:rotate()
    self.rotation = (self.rotation + 1) % 4
end

function Tile:goDown()
    if not isTaken(self.i, self.j - 1) then
        self.j = self.j - 1
        return true
    else
        self:die()
        return false
    end
end

function Tile:goRight()
    if not isTaken(self.i + 1, self.j) then
        self.i = self.i + 1
    end
end

function Tile:goLeft()
    if not isTaken(self.i - 1, self.j) then
        self.i = self.i - 1
    end
end

function Tile:goBottom()
    moved = true
    while moved do
        moved = self:goDown()
    end
end

function Tile:die()
    if self.i == 3 and self.j == 8 then
        gameState = 'over'
        return
    end


    -- check placement validity
    srl = getSlotRestrictionList()
    restr = srl[self.i]
    edges = self:getEdges()
    valid = true
    for i = 1, 3 do
        if restr:sub(i,i) ~= '-' then
            if restr:sub(i,i) ~= edges:sub(i,i) then
                valid = false
            end
        end
    end
    if not valid then
        gameState = 'over'
        return
    end

    -- place tile
    self.active = false
    deadTilesGrid[self.i][self.j] = self

    -- increase score
    score = score + speed

    clearRows()
    spawnNewTile()
end

function clearRows()
    for i = 1, 5 do
        if deadTilesGrid[i][2] == nil then
            return
        end
    end

    score = score + (10 * speed)
    for i = 1, 5 do
        for j = 2, 8 do
            tile = deadTilesGrid[i][j]
            if tile ~= nil then
                tile.j = tile.j - 1
            end
        end
        table.remove(deadTilesGrid[i], 1)
        deadTilesGrid[i][8] = nil
    end
end

function getSlotRestrictionList()
    ret = {}
    for i = 1, 5 do
        done = false
        for j = 1, 8 do
            if deadTilesGrid[i][j] == nil and not done then
                -- left
                if i == 1 or deadTilesGrid[i-1][j] == nil then
                    l = '-'
                else
                    l = deadTilesGrid[i-1][j]:getRight()
                end
                -- bottom
                if j == 1 or deadTilesGrid[i][j-1] == nil then
                    b = '-'
                else
                    b = deadTilesGrid[i][j-1]:getTop()
                end
                -- right
                if i == 5 or deadTilesGrid[i+1][j] == nil then
                    r = '-'
                else
                    r = deadTilesGrid[i+1][j]:getLeft()
                end
                table.insert(ret, l .. b .. r)
                done = true
            end
        end
    end
    return ret
end

function isTaken(i, j)
    if i < 1 or i > 5 or j < 1 then
        return true
    end
    for idx = 1, 5 do
        for jdx = 1, 8 do
            tile = deadTilesGrid[idx][jdx]
            if tile ~= nil then
                if tile.i == i and tile.j == j then
                    return true
                end
            end
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

function gridToPixelPos(i, j)
    ret = {}
    ret['x'] = ((i - 1) * 100) + 10
    ret['y'] = 700 - ((j - 1) * 100)
    return ret
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
deadTilesGrid = {}
for i = 1, 5 do
    deadTilesGrid[i] = {}
    for j = 1, 8 do
        deadTilesGrid[i][j] = nil
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
    for i = 1, 5 do
        for j = 1, 8 do
            if deadTilesGrid[i][j] ~= nil then
                deadTilesGrid[i][j]:draw()
            end
        end
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
    if scancode ~= nil and gameState == 'running' then
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
        end
        if scancode == 'p' then
            if gameState == 'running' then
                gameState = 'paused'
            elseif gameState == 'paused' then
                gameState = 'running'
            end
        end
    end
end

-- ###/ callback functions
