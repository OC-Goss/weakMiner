-- Miner V2
-- Author: weakman54
-- License: MIT (see bottom)


--------------------------------------------------------------------------
---- Config options ------------------------------------------------------
local vec3 = require("vector3")
local sides = require("sides")


local homePos = vec3(220, 11, 778) -- The position where the bot should start and end each mining operation

local startingBranch = 1 -- which branch index to start on
local numBranches = 2    -- How many branches to dig until program terminates
local branchDepth = 4    -- How deep each branch is, in scan chunks. Multiply by scanChunkSize to get number of blocks

local scanChunkSize = 8           -- The side length of the cube scanned when looking for ores
local trunkDir  = vec3( 0, 0, 1)  -- An orthogonal directional vector describing the direction the robot will use to dig the "trunk" of the mine
local branchDir = vec3(-1, 0, 0)  -- An orthogonal directional vector describing the direction the robot will start to dig when digging a branch. Should be perpendicular to the trunk
local shiftDir  = trunkDir         -- The direction to shift the robots position when digging back to the trunk from the end of a branch. trunkDir is a good default for this

local dumpInventorySide        = sides.negx  -- Absolute facing from homePos where the robot will dump it's inventory once it's done mining a branch
local maintenanceInventorySide = dumpInventorySide -- Absolute facing from homePos where the robot expects to find supplies for mining. Can be the same as dump inventory as long as needed resources are available when needed
-- Supplies used when mining:
  -- Sticks   used with diamonds to make new picks
  -- Diamonds used with sticks to make new picks
  -- Coal     used for fuel. TODO: make the type of fuel configurable

local pickaxeDurabilityTreshold = 1000 -- If durability is below this, the bot will craft a new pick
local allowCombinePicks = true




--------------------------------------------------------------------------
---- Code ----------------------------------------------------------------
local robot = require("robot")
local component = require("component")
local computer = require("computer")
local filesystem = require("filesystem")

local geo = component.geolyzer
local gen = component.generator
local crafting = component.crafting
local inv = component.inventory_controller

local nibnav = require("nibnav")
local nibinv = require("nibinv")

local geoUtil = dofile("util_geolyzer.lua")
local roboUtil = dofile("util_robot.lua")



--------------------------------------------------------------------------
---- Maintenance stuff, could maybe be moved into other place?? vvvvvvvvvv
-- Miner refueling
-- Assumes empty slot 1
-- Assumes coal in inventory
local function refuel()
  print("Refueling")
  nibnav.faceSide(maintenanceInventorySide)

  robot.select(1)

  local coalCount = nibinv.getTotal(sides.front, "Coal")
  local fuelNeeded = 64 - gen.count()

  if coalCount < fuelNeeded then
    error("Not enough coal in dump inventory for refuel!")
  end

  local slot, _ = nibinv.items(sides.front, "Coal")()
  inv.suckFromSlot(sides.front, slot, fuelNeeded)
  gen.insert()
end


-- Miner tool check
local function checkTool()
  nibnav.faceSide(maintenanceInventorySide)
  robot.select(1)
  inv.equip()
  local is = inv.getStackInInternalSlot(1)

  local dur = is.maxDamage - is.damage
  print("old pick durability: ", dur)
  if dur < pickaxeDurabilityTreshold then
    robot.drop()
    print("Dropping pick")

  else
    print("Enough durability, keeping pick")
    inv.equip()
    return

  end

  local numPicks = nibinv.getTotal(sides.front, "Diamond Pickaxe")

  print("numPicks:", numPicks)

  if allowCombinePicks and numPicks > 1 then
    print("More than one pick, combining")
    for slot, is in nibinv.items(sides.front, "Diamond Pickaxe") do
      inv.suckFromSlot(sides.front, slot)
    end

  else
    print("Not enough picks to combine, crafting new one")
    local dimCount = nibinv.getTotal(sides.front, "Diamond")
    local stkCount = nibinv.getTotal(sides.front, "Stick")
    assert(dimCount >= 3, "Not enough diamonds!")
    assert(stkCount >= 2, "Not enough sticks!")

    local slot, is = nibinv.items(sides.front, "Diamond")()
    inv.suckFromSlot(sides.front, slot, 1)

    robot.select(2)
    inv.suckFromSlot(sides.front, slot, 1)

    robot.select(3)
    inv.suckFromSlot(sides.front, slot, 1)


    slot, is = nibinv.items(sides.front, "Stick")()
    robot.select(6)
    inv.suckFromSlot(sides.front, slot, 1)

    robot.select(10)
    inv.suckFromSlot(sides.front, slot, 1)
  end
  
  robot.select(4)
  crafting.craft()
  is = inv.getStackInInternalSlot(4)
  dur = is.maxDamage - is.damage
  print("new pick durability: ", dur)
  inv.equip()
end


local function maintenance()
  print("Maintenance")
  -- Assumes empty inventory
--  nibnav.faceSide(dumpInventorySide)
--  roboUtil.dumpInventory()
  
  -- Empty current fuel, we should be on a chargepad
  nibnav.faceSide(maintenanceInventorySide)
  robot.select(1)
  gen.remove() 
  robot.drop()

--  roboUtil.dumpInventory(12) -- Again, inventory should be empty
  checkTool()


--  roboUtil.dumpInventory()-- Again, inventory should be empty
  refuel()
end


-- Log some values before getting back to the charging pad
local function preMaintenanceCheck()
  print("Premaintenance check")
  print("Energy level: ", computer.energy())
  print("Generator count: ", gen.count())
end
--- Maintenance stuff, could maybe be moved into other place?? ^^^^^^^^^^
--------------------------------------------------------------------------





-- Could be moved to robo utils probably?
local function distanceFromRobot(pos)
  return vec3(nibnav.getPosition()):distanceTo(pos)
end



-- Tries to move to the target position
-- if allowDigging is true, it will use robot.swing on any block it can't go to before moving
-- The order of x, y, z to move in can be rearranged by rearranging the if's below, though I want to fix this to be easier at some point
local function moveToBlock(target, allowDigging)
  local roboPos = vec3(nibnav.getPosition())
  local delta = target - roboPos

  while not delta:isZero() do
    roboPos  = vec3(nibnav.getPosition())
    delta = target - roboPos

    if false then -- Dummy if to make it easier to rearrage the below if statements to better fit whichever facing TODO: make this unneccessary

      -- Y Move --
    elseif delta.y > 0 then
      while allowDigging and geo.detect(sides.up) do robot.swingUp() end
      nibnav.up()

    elseif delta.y < 0 then
      while allowDigging and geo.detect(sides.down) do robot.swingDown() end
      nibnav.down()


      -- Z Move --
    elseif delta.z > 0 then
      nibnav.faceSide(sides.posz)
      while allowDigging and geo.detect(sides.front) do robot.swing() end
      nibnav.forward()

    elseif delta.z < 0 then
      nibnav.faceSide(sides.negz)
      while allowDigging and geo.detect(sides.front) do robot.swing() end
      nibnav.forward()


      -- X Move --
    elseif delta.x > 0 then
      nibnav.faceSide(sides.posx)
      while allowDigging and geo.detect(sides.front) do robot.swing() end
      nibnav.forward()

    elseif delta.x < 0 then
      nibnav.faceSide(sides.negx)
      while allowDigging and geo.detect(sides.front) do robot.swing() end
      nibnav.forward()

    end

  end
end




-- Scans the surrounding blocks for ores
-- Returns a list of absolute coordinates that represent ores
-- TODO: could be refactored to scan for any "type" of block (as described by a guess function)
local function getOres()
  local ores = {}

  for x=-1, 0 do
    for y=-1, 0 do
      for z=-1, 0 do
        local d = geoUtil.getAllInVolume(geoUtil.volumeScan, geoUtil.guessOres, nil, vec3(4, 4, 4), vec3(x*4, y*4, z*4))

        for k, cd in pairs(d) do
          if cd.guess == "ore" then
--            print("found ore")
            local roboPos = vec3(nibnav.getPosition())
            local orePos = roboPos + cd.relPos
--            print(orePos)
            table.insert(ores, orePos)

          end
        end
      end
    end
  end

  return ores
end


-- Digs all ores found by getOres
-- If returnToStart is true (defaults to true if omitted), the bot will return to the positon it started at
-- Uses a naive Nearest Neighbour algorithm
-- TODO: factor out call to getOres and send in a list of positions instead
local function digOres(returnToStart)
  if returnToStart == nil then returnToStart = true end

  local start = vec3(nibnav.getPosition())


  local ores = getOres()

  while #ores > 0 do
    table.sort(ores, function(a, b) return distanceFromRobot(a) < distanceFromRobot(b) end)
    moveToBlock(ores[1], true)
    table.remove(ores, 1)
  end


  if returnToStart then moveToBlock(start, true) end
end




-------------------------------------------------------------
-- PROGRAM --------------------------------------------------
-------------------------------------------------------------
print("Miner program V2.1")
print("Reference version 1")

computer.beep(880 , 0.1)
computer.beep(880 , 0.1)
computer.beep(1100, 0.4)


-- Setup ------------------
do -- Sanity check on nibnav position as a stopgap if wps is not used
  local x, y, z = nibnav.getPosition()
  if x == 0 and y == 0 and z == 0 then
    print("Robot at 0, 0, 0. This is probably not correct!")
    print("remember to set nibnav position before using the miner script!")
    print("Terminating")
    computer.beep(220, 1)
    return
  end
end

local startTime = computer.uptime()
local refTime


-------------------------------------
-- Main loop ------------------------
-------------------------------------
for branchI=startingBranch, startingBranch+numBranches-1 do
  print("\n-------------------------")
  print("Loop iteration")
  print("Next branch: ", branchI)


  -- Start-of-loop maintenance ----
  print("\nPre dig maintenance")
  refTime = computer.uptime()
  maintenance()
  print("Maintenance done, time:", computer.uptime() - refTime)


  -- Mining loops -------------------
  print("\nPreparations complete, digging branch: ", branchI)
  computer.beep(880, 0.1)
  refTime = computer.uptime()

  local branchPos = homePos + trunkDir*scanChunkSize * (2*branchI - 1)

  moveToBlock(branchPos, true)

  for i=1, branchDepth do
    moveToBlock(branchPos + branchDir*scanChunkSize*i, true)
    digOres()
  end

  for i=branchDepth, 1, -1 do
    moveToBlock(branchPos + branchDir*scanChunkSize*i + shiftDir*scanChunkSize, true)
    digOres()
  end
  
  moveToBlock(branchPos + shiftDir*scanChunkSize, true) -- Dig back to the trunk once done with the last scan chunk
  
  preMaintenanceCheck() -- This needs to be before we move to home, since there's a chargingpad there
  moveToBlock(homePos, true)
  
  nibnav.faceSide(dumpInventorySide)
  roboUtil.dumpInventory()

  computer.beep(880, 0.1)
  print("\nDone digging branch:", branchI)
  print("time:", computer.uptime() - refTime)
end



--[[
MIT License

Copyright (c) 2020 weakman54

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]