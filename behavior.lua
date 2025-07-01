-- These comments were written as of 2023-2024, and is not reflective of my current state as a programmer.
--
-- I use a variant of Lua called Luau
-- It's used in the game ROBLOX, and mainly used on its creation engine known as ROBLOX Studio
-- This is the part where I am most proficient in - I've been familiarizing myself with the API and learning all the ins and outs of the engine since 2017-2018.
-- If needed, I can send videos of my games and works, but here I am going to deposit some pieces of code proving my familiarity with programming.

local module = {}
local stanFuncs = require(game.ReplicatedStorage.Modules.StandardizedFunctions)
local sharedData = nil
local currentCheckpoint = nil
local moving = false
local lastCheckpointReached = 0

local movingToLKL = false

local function fisherYatesShuffle(t)
	local output = {}
	local random = math.random

	for index = 1, #t do
		local offset = index - 1
		local value = t[index]
		local randomIndex = offset*random()
		local flooredIndex = randomIndex - randomIndex%1

		if flooredIndex == offset then
			output[#output + 1] = value
		else
			output[#output + 1] = output[flooredIndex + 1]
			output[flooredIndex + 1] = value
		end
	end

	return output
end

local function getAveragePlayerPos()
	local pos = Vector3.new()
	local items = 0

	for _, v in pairs(game.Players:GetPlayers()) do
		local character = v.Character or v.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart")

		pos += root.Position
		items += 1
	end

	return pos / items
end

local function disconnect()
	if currentCheckpoint then
		local occupiedValue = currentCheckpoint:FindFirstChild("Occupied")
		if occupiedValue then
			occupiedValue:Destroy()
		end
		
		moving = false
		currentCheckpoint = nil
	end
end

local function healthChanged()
	if myHumanoid.Health <= 0 then
		disconnect()
	end
end

local function attributeChanged()
	if myCharacter:GetAttribute("Intimidations") <= 0 then
		print('surrendahs,.,. lolz')
		
		disconnect()
	end
end

local function lastKnownLocationChanged()
	movingToLKL = true
	
	sharedData.Functions.Pathfinding:MoveTo(game.ReplicatedStorage.Values.LastKnownLocation.Value)
end

function module:GetCheckpoint()
	local map = workspace:FindFirstChild("Map")
	
	if map and map:FindFirstChild("PatrolPoints") then
		local pool = {}
		local avgPos = getAveragePlayerPos()
		
		for _, v in pairs(map.PatrolPoints:GetChildren()) do
			local vPos = v:GetPivot().Position
			local distance = (vPos - avgPos).Magnitude
			local yDifference = math.abs(vPos.Y - avgPos.Y)
			
			if yDifference <= 10 and distance <= 65 and not v:FindFirstChild("Occupied") then
				table.insert(pool, v)
			end
		end
		
		print(pool)
		
		return pool[stanFuncs:RandomInteger(1, #pool)]
	end
	
	return nil
end

function module:PatrolLogic()
	if myCharacter:GetAttribute("Patroller") and not myCharacter:GetAttribute("SuspectingTarget") then
		if not movingToLKL then
			if targetValue.Value then
				moving = false
				myCharacter:SetAttribute("Patroller", false)
			end
			
			if tick() - lastCheckpointReached >= myCharacter:GetAttribute("CheckpointRestDuration") and not moving then
				if currentCheckpoint and currentCheckpoint:FindFirstChild("Occupied") then
					currentCheckpoint.Occupied:Destroy()
					
					currentCheckpoint = nil
				end
				
				moving = true
				lastCheckpointReached = 0
				
				currentCheckpoint = module:GetCheckpoint()
				
				local occupiedValue = Instance.new("ObjectValue")
				occupiedValue.Parent = currentCheckpoint
				occupiedValue.Name = "Occupied"
				occupiedValue.Value = myCharacter
				
				print('movin to the next checkpoint')
			end
			
			if moving and not targetValue.Value and currentCheckpoint then
				local checkpointPos = currentCheckpoint:GetPivot().Position
				
				sharedData.Functions.Pathfinding:MoveTo(checkpointPos)
				
				local flattenedRootPos = Vector3.new(myRoot.Position.X, 0, myRoot.Position.Z)
				local flattenedCheckpointPos = Vector3.new(checkpointPos.X, 0, checkpointPos.Z)
				if (flattenedRootPos - flattenedCheckpointPos).Magnitude <= 1 then
					print('reached')
					sharedData.Functions.Sight:TorsoLook(myRoot.Position + (currentCheckpoint.CFrame.LookVector * 3))
					
					moving = false
					lastCheckpointReached = tick()
				end
			end
		else
			local pos = game.ReplicatedStorage.Values.LastKnownLocation.Value
			local distance = (myRoot.Position - pos).Magnitude
			
			if distance <= 3 then
				movingToLKL = false
			end
		end
	end
end

function module:Initialize(sharedVariables)
	myCharacter = sharedVariables.Character
	myRoot = myCharacter:WaitForChild("HumanoidRootPart")
	myHumanoid = myCharacter:WaitForChild("Humanoid")
	
	targetValue = myCharacter:WaitForChild("Target")
	
	myCharacter:SetAttribute("CheckpointRestDuration", stanFuncs:RandomInteger(4, 12))
	
	local lastKnownLocationEvent = game.ReplicatedStorage.Values.LastKnownLocation.Changed:Connect(lastKnownLocationChanged)
	local healthChangedConnection = myHumanoid.HealthChanged:Connect(healthChanged)
	local attributeChangedConnection = myCharacter.AttributeChanged:Connect(attributeChanged)
	
	table.insert(sharedVariables.Connections, healthChangedConnection)
	table.insert(sharedVariables.Connections, attributeChangedConnection)
	table.insert(sharedVariables.Connections, lastKnownLocationEvent)
	
	sharedData = sharedVariables
end

return module
