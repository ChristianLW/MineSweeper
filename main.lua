-- Mines table:
-- -1 = Cell is a mine
-- 0-8 = Number of neighbouring mines

-- Player table:
-- 0 = Unknown
-- 1 = Uncovered
-- 2 = Flag

-- Game State:
-- -1 = New game
-- 0 = Playing
-- 1 = Won
-- 2 = Lost

function love.load(args, unfilteredArgs)
	-- Playing the same game every time is a bit boring
	math.randomseed(os.time())
	-- A bit too small otherwise
	zoom = 2
	-- Boxes of different colours aren't enough
	texture = love.graphics.newImage("textures.png")
	-- Make sure it doesn't become a blurry mess when zooming
	texture:setFilter("nearest")
	-- textures.png is a texture atlas, so we need to chop it up into bits (i.e. quads)
	QUADS = {
		UNKNOWN = love.graphics.newQuad(0, 0, 16, 16, 64, 64),
		FLAG = love.graphics.newQuad(16, 0, 16, 16, 64, 64),
		MINE = love.graphics.newQuad(32, 0, 16, 16, 64, 64),
		NONE = love.graphics.newQuad(48, 0, 16, 16, 64, 64),
		love.graphics.newQuad(0, 16, 16, 16, 64, 64),
		love.graphics.newQuad(16, 16, 16, 16, 64, 64),
		love.graphics.newQuad(32, 16, 16, 16, 64, 64),
		love.graphics.newQuad(48, 16, 16, 16, 64, 64),
		love.graphics.newQuad(0, 32, 16, 16, 64, 64),
		love.graphics.newQuad(16, 32, 16, 16, 64, 64),
		love.graphics.newQuad(32, 32, 16, 16, 64, 64),
		love.graphics.newQuad(48, 32, 16, 16, 64, 64)
	}
	-- The display for showing the number of mines left as well as other info, size is 68x43
	display = love.graphics.newImage("display.png")
	-- Also need some digits to display the numbers
	digits = love.graphics.newImage("digits.png")
	-- Again, digits.png is a texture atlas (this time only horizontally, though)
	DIGIT_QUADS = {}
	for i = 0, 9 do
		DIGIT_QUADS[tostring(i)] = love.graphics.newQuad(i * 16, 0, 16, 31, 160, 31)
	end
	-- And finally initialise a new game with size 24x16 and 64 mines
	-- Alternatively the player can specify the parameters
	local gameWidth = math.max(tonumber(string.match(args[1] or "", "^%d*$")) or 24, 4)
	local gameHeight = math.max(tonumber(string.match(args[2] or "", "^%d*$")) or 16, 4)
	local numMines = 64
	if args[3] then
		if tonumber(args[3]) then
			numMines = math.floor(tonumber(args[3]))
		elseif args[3]:sub(-1) == "%" then
			local percent = tonumber(args[3]:sub(1, -2))
			if percent and percent >= 0 and percent <= 100 then
				numMines = math.floor(gameWidth * gameHeight * percent / 100)
			end
		end
	end
	-- Make sure that no more than half of the cells are filled with mines
	numMines = math.min(numMines, math.floor(gameWidth * gameHeight / 2))
	newGame(gameWidth, gameHeight, numMines)
	-- We also need to create the confetti table
	confetti = {}
end

function love.update(dt)
	-- Empty for now, will probably remain that way tbh
	-- EDIT: I decided to add confetti
	-- And confetti usually moves, so I'll make it do that here
	-- If the game has been won, then spawn some confetti
	if gameState == 1 then
		table.insert(confetti, {
			x = math.random(0, love.graphics.getWidth()),
			y = 0,
			velX = 0,
			velY = 1 + math.random(),
			angle = 0,
			rotVel = (math.random() - 0.5) * math.pi / 8,
			colour = {rgbFromHue(math.random() * 6)}
		})
	end
	for k, v in pairs(confetti) do
		v.velX = clamp(v.velX + math.random() - 0.5, -2, 2)
		v.velY = v.velY
		v.x = v.x + v.velX
		v.y = v.y + v.velY
		v.angle = v.angle + v.rotVel
		if v.y > love.graphics.getHeight() then
			table.remove(confetti, k)
			k = k - 1
		end
	end
end

function love.draw()
	love.graphics.clear(192 / 255, 192 / 255, 192 / 255)
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	-- Draw the display showing the number of mines left
	drawDisplay(math.max(gameInfo.numMines - flags, 0), 10, 10)
	-- Draw the game
	love.graphics.draw(batch, 0, 63, 0, zoom)
	-- Draw all the confetti
	for k, v in pairs(confetti) do
		love.graphics.setColor(v.colour)
		love.graphics.translate(v.x, v.y)
		love.graphics.rotate(v.angle)
		love.graphics.rectangle("fill", -4, -4, 8, 8)
		love.graphics.origin()
	end
end

function drawDisplay(value, x, y)
	love.graphics.draw(display, x, y)
	local str = string.format("%03u", value)
	for i = 1, 3 do
		love.graphics.draw(digits, DIGIT_QUADS[str:sub(i, i)], x + 6 + (i - 1) * 20, y + 6)
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	-- If the game is over, then start a new one with same width, height, and number of mines
	if gameState > 0 then
		newGame(gameInfo.width, gameInfo.height, gameInfo.numMines)
		-- Make the confetti move faster downwards to clear it more quickly
		for k, v in pairs(confetti) do
			v.velY = v.velY * 8
		end
		return
	end
	-- Get which cell was clicked on
	local cellX, cellY = math.floor(x / 16 / zoom), math.floor((y - 63) / 16 / zoom)
	-- If the player clicked outside the game area, then just give up on life
	if cellX > gameInfo.width or cellY < 0 or cellY > gameInfo.height then return end
	-- LMB
	if button == 1 then
		if gameState == -1 then
			generateMines(cellX, cellY)
		end
		-- Clicked on not yet uncovered cell
		if player[cellY][cellX] == 0 then
			floodFill(cellX, cellY)
		-- Clicked on uncovered numbered cell
		elseif player[cellY][cellX] == 1 and mines[cellY][cellX] > 0 then
			floodFill(cellX - 1, cellY - 1)
			floodFill(cellX, cellY - 1)
			floodFill(cellX + 1, cellY - 1)
			floodFill(cellX - 1, cellY)
			floodFill(cellX, cellY)
			floodFill(cellX + 1, cellY)
			floodFill(cellX - 1, cellY + 1)
			floodFill(cellX, cellY + 1)
			floodFill(cellX + 1, cellY + 1)
		end
		-- If the player has uncovered all cells, except those with mines, ya boi got WIN
		if uncovered == gameInfo.width * gameInfo.height - gameInfo.numMines then
			gameState = 1
			-- Put in any final missing flags
			for x = 0, gameInfo.width - 1 do
				for y = 0, gameInfo.height - 1 do
					if mines[y][x] == -1 and player[y][x] ~= 2 then
						setFlag(x, y, true)
					end
				end
			end
		end
	-- RMB
	elseif button == 2 then
		-- Place flag
		if player[cellY][cellX] == 0 then
			setFlag(cellX, cellY, true)
		-- Remove flag
		elseif player[cellY][cellX] == 2 then
			setFlag(cellX, cellY, false)
		end
	end
end

function setFlag(x, y, state)
	if state and player[y][x] ~= 0 or not state and player[y][x] ~= 2 then return false end
	batch:set(x + y * gameInfo.width + 1, state and QUADS.FLAG or QUADS.UNKNOWN, x * 16, y * 16)
	player[y][x] = state and 2 or 0
	if state then flags = flags + 1 else flags = flags - 1 end
	return true
end

function newGame(width, height, numMines)
	-- If this is a new session or if the game width/height has changed, resize the window
	if not gameInfo or width ~= gameInfo.width or height ~= gameInfo.height then
		love.window.updateMode(width * 16 * zoom, height * 16 * zoom + 63)
	end
	-- Set the game info variables
	gameInfo = {
		width = width,
		height = height,
		numMines = numMines
	}
	-- Initialise everything
	mines = {}
	player = {}
	flags = 0
	uncovered = 0
	batch = love.graphics.newSpriteBatch(texture, width * height)
	-- Put in the grid
	for y = 0, height - 1 do
		mines[y] = {}
		player[y] = {}
		for x = 0, width - 1 do
			mines[y][x] = 0
			player[y][x] = 0
			batch:add(QUADS.UNKNOWN, x * 16, y * 16)
		end
	end
	-- Better to do it here than in love.draw
	batch:flush()
	-- And finally, tell the game that it's running
	gameState = -1
end

function generateMines(startX, startY)
	for i = 0, gameInfo.numMines - 1 do
		local x, y
		while x == nil or y == nil or mines[y][x] == -1 or (x >= startX - 1 and x <= startX + 1 and y >= startY - 1 and y <= startY + 1) do
			x, y = math.random(0, gameInfo.width - 1), math.random(0, gameInfo.height - 1)
		end
		mines[y][x] = -1
		-- Put in the numbers
		for numX = math.max(x - 1, 0), math.min(x + 1, gameInfo.width - 1) do
			for numY = math.max(y - 1, 0), math.min(y + 1, gameInfo.height - 1) do
				if mines[numY][numX] ~= -1 then mines[numY][numX] = mines[numY][numX] + 1 end
			end
		end
	end
	gameState = 0
end

function floodFill(x, y)
	-- If outside game, don't try to do anything, game will crash =)
	if x < 0 or x > gameInfo.width - 1 or y < 0 or y > gameInfo.height - 1 then return false end
	-- If the cell is already uncovered or a flag, QUIT
	if player[y][x] ~= 0 then return false end
	-- Uncover the cell
	player[y][x] = 1
	uncovered = uncovered + 1
	-- If cell is a mine, ya boi lost
	if mines[y][x] == -1 then
		batch:set(x + y * gameInfo.width + 1, QUADS.MINE, x * 16, y * 16)
		gameState = 2
		return false
	-- If the cell is numbered, then leave
	elseif mines[y][x] > 0 then
		batch:set(x + y * gameInfo.width + 1, QUADS[mines[y][x]], x * 16, y * 16)
		return false
	end
	-- If the cell is 100% empty, then do the floodfill thing
	batch:set(x + y * gameInfo.width + 1, QUADS.NONE, x * 16, y * 16)
	floodFill(x - 1, y - 1)
	floodFill(x, y - 1)
	floodFill(x + 1, y - 1)
	floodFill(x - 1, y)
	floodFill(x + 1, y)
	floodFill(x - 1, y + 1)
	floodFill(x, y + 1)
	floodFill(x + 1, y + 1)
	return true
end

function clamp(x, min, max)
	if x < min then return min
	elseif x > max then return max end
	return x
end

function rgbFromHue(hue)
	if hue < 0 then return
	elseif hue < 1 then return 1, hue, 0
	elseif hue < 2 then return -hue + 2, 1, 0
	elseif hue < 3 then return 0, 1, hue - 2
	elseif hue < 4 then return 0, -hue + 4, 1
	elseif hue < 5 then return hue - 4, 0, 1
	elseif hue < 6 then return 1, 0, -hue + 6
	else return end
end
