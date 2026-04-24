-- title: Critter Crossing
-- author: Alex Mayer
-- desc: Jump over stuff with cute characters
-- site: https://gitlab.com/amayer5125/critter-crossing
-- license: MIT License
-- version: 0.1.0
-- script: lua
-- input: gamepad
-- saveid: CritterCrossing

mode = "title"
player = {}
playerSprites = { 256, 258, 260, 262 }
course = {}
groundTiles = {}
clouds = {}
minimum_between_obstacles = 120
score = 0
show_tutorial = true
init = true
current_tick = 0

function BOOT()
	math.randomseed(tstamp())
end

function TIC()
	if init then
		initGame()
		init = false
	end

	if mode == "game" then
		game()
	elseif mode == "dead" then
		dead()
	elseif mode == "title" then
		title()
	end

	current_tick = current_tick + 1
end

function game()
	cls(8)

	if current_tick % 8 == 0 then
		score = score + 1
	end

	-- increase speed every so many ticks
	if current_tick % 120 == 0 then
		course.vx = course.vx - 0.1
	end

	drawClouds()
	drawCourse()
	drawScore(score)
	movePlayer()
	checkCollisions()
	drawPlayer()

	if show_tutorial then
		print("Press A to jump", 78, 70, 5)

		if btnp(4) or btnp(0) then
			show_tutorial = false
		end
	end


	if player.dead then
		mode = "dead"
		if score > pmem(0) then
			pmem(0, score)
		end
	end

	-- debug = {
	-- 	current_tick,
	-- 	course.vx * -1,
	-- }
	-- for i = 1, #debug do
	-- 	print(debug[i], 1, (i-1)*8+1, 0)
	-- end
end

function dead()
	cls(8)

	course.vx = 0

	drawCourse()
	drawScore(score)
	drawPlayer()

	print("Game Over!", 37, 32, 12, false, 3)
	local can_restart = current_tick - player.dead > 45
	if can_restart then
		print("Press A to restart", 70, 56, 12)
		print("Press B for characters", 57, 64, 12)

		if btnp(4) then
			init = true
			mode = "game"
		elseif btnp(5) then
			mode = "title"
		end
	end
end

current_character = 1
function title()
	cls(8)

	print("Critter", 61, 10, 12, false, 3)
	print("Crossing", 52, 28, 12, false, 3)
	print("Select character", 73, 61, 5)
	print("Then press A", 86, 69, 5)

	high_score = pmem(0)
	if high_score > 0 then
		drawScore(high_score)
	end

	-- draw cliff
	for x = 0, 15 do
		spr(3, x*16, 88, 0, 1, 0, 0, 2, 6)
	end

	local characters = {
		{sprite = 256, x = 22, y = 94},
		{sprite = 288, x = 82, y = 94},
		{sprite = 320, x = 142, y = 94},
		{sprite = 352, x = 202, y = 94},
	}
	for i = 1, #characters do
		local character = characters[i]
		spr(character.sprite, character.x, character.y, 0, 1, 0, 0, 2, 2)
	end

	if btnp(2) then
		current_character = current_character - 1
		if current_character < 1 then
			current_character = #characters
		end
	elseif btnp(3) then
		current_character = current_character + 1
		if current_character > #characters then
			current_character = 1
		end
	end

	-- arrow
	spr(7, characters[current_character].x, 77, 0, 1, 0, 2, 2, 2)

	if btnp(4) then
		local sprit = characters[current_character].sprite
		playerSprites = {sprit, sprit + 2, sprit + 4, sprit + 6}

		init = true
		mode = "game"
	end
end

function drawCourse()
	local tiles_to_remove = 0
	for i = 1, #groundTiles do
		local ground = groundTiles[i]
		ground.x = ground.x + course.vx
		if ground.x <= -16 then
			tiles_to_remove = tiles_to_remove + 1
		else
			spr(ground.sprite, round(ground.x, 2), 88, 0, 1, 0, 0, 2, 6)
		end
	end
	for _ = 1, tiles_to_remove do
		table.remove(groundTiles, 1)
		table.insert(groundTiles, {
			sprite = 3,
			x = groundTiles[#groundTiles].x + 16,
		})
	end

	local obstacles_to_remove = 0
	for i = 1, #course.obstacles do
		local obstacle = course.obstacles[i]
		obstacle.x = obstacle.x + course.vx
		if obstacle.x <= -16 then
			obstacles_to_remove = obstacles_to_remove + 1
		else
			spr(obstacle.sprite, round(obstacle.x, 2), obstacle.y, 0, 1, 0, 0, obstacle.width, obstacle.height)
		end
	end
	for _ = 1, obstacles_to_remove do
		table.remove(course.obstacles, 1)
		table.insert(course.obstacles, generateObstacle(course.obstacles[#course.obstacles].x + minimum_between_obstacles))
	end
end

function movePlayer()
	if player.y < player.desiredY then
		player.vy = player.vy + 0.27
	end

	if player.y >= player.desiredY then
		player.y = player.desiredY
		player.vy = 0
	end

	if (btn(4) or btn(0)) and player.y == player.desiredY then
		player.vy = -player.jump_height
	end

	player.y = player.y + player.vy
end

function drawPlayer()
	local spriteIndex

	if player.dead then
		spriteIndex = 4
	elseif player.y ~= player.desiredY then
		spriteIndex = 3
	else
		spriteIndex = 1 + current_tick % 16 // 8
	end

	spr(playerSprites[spriteIndex], player.x, player.y, 0, 1, 0, 0, 2, 2)
end

function drawClouds()
	local clouds_to_remove = {}
	for i = 1, #clouds do
		local cloud = clouds[i]
		cloud.x = cloud.x + course.vx / 4
		if cloud.x <= -8 * cloud.width then
			clouds_to_remove[#clouds_to_remove+1] = i
		else
			spr(cloud.sprite, cloud.x, cloud.y, 0, 1, 0, 0, cloud.width, cloud.height)
		end
	end
	for i = 1, #clouds_to_remove do
		table.remove(clouds, clouds_to_remove[i])
		table.insert(clouds, generateCloud(240))
	end
end

function drawScore(score)
	local width = print(score, 0, -16)
	print(score, 240-width-2, 3, 5)
end

function checkCollisions()
	for i = 1, #course.obstacles do
		local obstacle = course.obstacles[i]
		-- obstacle made narrower to favor the player
		if collision(player.x, player.y, player.width, player.height, obstacle.x+4, obstacle.y+2, obstacle.width*8-8, obstacle.height*8-2) then
			player.dead = current_tick
		end
	end
end

function generateCloud(x)
	local cloud_options = {
		{sprite = 39, width = 4, height = 2, minimum_y = 30, maximum_y=65},
		{sprite = 43, width = 4, height = 2, minimum_y = 10, maximum_y=40},
	}

	local cloud = cloud_options[math.random(#cloud_options)]
	return {
		x = x,
		y = math.random(cloud.minimum_y, cloud.maximum_y),
		sprite = cloud.sprite,
		height = cloud.height,
		width = cloud.width,
	}
end

function generateObstacle(minimum_x)
	minimum_x = minimum_x or 240

	local obstacle_options = {
		{sprite = 9, height = 2, width = 2},
		{sprite = 11, height = 2, width = 2},
	}

	local obstacle = obstacle_options[math.random(#obstacle_options)]
	return {
		x = minimum_x + math.random(0, 200),
		y = 110 - (obstacle.height * 8),
		sprite = obstacle.sprite,
		height = obstacle.height,
		width = obstacle.width,
	}
end

function collision(x1, y1, w1, h1, x2, y2, w2, h2)
	return x1 < x2 + w2 and
			x1 + w1 > x2 and
			y1 < y2 + h2 and
			y1 + h1 > y2
end

function round(number, decimal_places)
	local multiplier = 10 ^ (decimal_places or 0)
	return math.floor(number * multiplier + 0.5) / multiplier
end

function initGame()
	current_tick = 0
	score = 0

	player = {
		x = 10,
		y = 0,
		height = 16,
		width = 16,
		vy = 0,
		jump_height = 4,
		desiredY = 94,
		dead = false,
	}
	course = {
		x = 0,
		y = 0,
		vx = -1.5,
		obstacles = {},
	}

	groundTiles = {}
	local x = 48
	table.insert(groundTiles, {
		sprite = 1,
		x = x,
	})
	for _ = 1, 16 do
		x = x + 16
		table.insert(groundTiles, {
			sprite = 3,
			x = x,
		})
	end

	local number_of_obstacles = 240 // minimum_between_obstacles + 1
	x = 240
	for _ = 1, number_of_obstacles do
		local new_obstacle = generateObstacle(x)
		table.insert(course.obstacles, new_obstacle)
		x = new_obstacle.x + minimum_between_obstacles
	end

	clouds = {}
	for i = 1, 4 do
		local new_cloud = generateCloud(i * 60)
		table.insert(clouds, new_cloud)
	end
end
