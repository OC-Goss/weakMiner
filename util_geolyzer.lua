-- Geolyzer scanning utilities (V2)
-- Author: weakman54

local geo = require("component").geolyzer

local vec3 = require("vector3")


local gu = {}

-- Returns the maximum deviation from actual hardness value, given the distance to the block scanned
-- ConfigC is the "geolyzer maximum deviation" described in the config files, default is 2
-- NOTE: noise values can be larger than this value due to a bug in the geolyzer code
-- The geolyzer expects a max distance of 33 (the maximum vertical distance).
-- But it actually uses the euclidean distance, which can maximally be 57, so for the default config value of 2, we get:
-- 57 * (1/33) * 2 ~ 3.5
-- If this is fixed, the 33 below should be changed to 57
function gu.maxDeviationFromDistance(distance, configC)
  return distance * (1/33) * (configC or 2)
end


-- Scans a volume of the given size and offset from the geolyzer
-- Returns a list of tables which are formatted like so:
-- 	minHardness: The calculated minimum hardness of the block, given the blocks distance from the geolyzer
--	maxHardness: The calculated maximum hardness of the block, given the blocks distance from the geolyzer
--	relPos: The position of the scanned block, relative to the geolyzer (In absolute coordinates. a negative relX means that many blocks in the direction of sides.negx)
function gu.volumeScan(size, offset)
  local data = geo.scan(offset.x, offset.z, offset.y, size.x, size.z, size.y)

  local retData = {}

  for y=0, size.y-1 do
    for z=0, size.z-1 do
      for x=0, size.x-1 do
        local i = size.x*size.z*y + size.x*z + x + 1
        local relPos = vec3(x, y, z) + offset

        retData[i] = {minHardness = 0, maxHardness = 0, relPos = relPos}

        local hardness = data[i]

        if hardness == 0 -- Definitely air, we don't need to know any more	
        or relPos:isZero() then -- geolyzer position, aka, air (NOTE/FIXME: this is wrong if the gelyzer is a block, and not in a robot)
          goto scanDataLoopVolume_continue

        end


        local maxDeviation = gu.maxDeviationFromDistance(relPos:len())

        retData[i].minHardness = hardness - maxDeviation
        retData[i].maxHardness = hardness + maxDeviation


        ::scanDataLoopVolume_continue::
      end
    end
  end

  return retData
end



-- Returns a string that describes the type of block
-- returns "unknown" if block type cannot be determined
-- reference: https://minecraft.gamepedia.com/Breaking#Blocks_by_hardness
function gu.guess(minHardness, maxHardness)
  if minHardness == 0 and maxHardness == 0 then
    return "air"

  elseif maxHardness < 0 then
    return "unbreakable"

  elseif minHardness > 2.5 and maxHardness < 3.5 then -- NOTE: there are a number of blocks within this range that are not ores, but are very unlikely to appear while mining for ore underground
    return "ore"

  elseif minHardness > 22 and maxHardness < 100 then
    return "obsidian"

  elseif minHardness > 50 then 
    return "liquid" -- Needs some additional testing, but should be mostly correct

  elseif minHardness > -1 and maxHardness <= 2.5 then
    return "misc_low"

  elseif minHardness >= 3.5 and maxHardness <= 22 then
    return "misc_high"

  else
    return "unknown"

  end
end

-- Ore focused scan
function gu.guessOres(minHardness, maxHardness)
  if minHardness > 2 and maxHardness < 4 then
    return "ore"

  elseif maxHardness < 3 then
    return "misc_low"

  elseif minHardness > 3 then
    return "misc_high"

  else
    return "unknown"

  end
end



-- repeatedly scans using the given scan function until a "type" has been found for all blocks (or until maxIter is reached)
-- the type of a block is given by guessF, which has the signature:
-- 	guessF(minHardness, maxHardness)
-- and returns a string denoting the type. The string should be "unknown" if the type cannot be calculated
-- Any other returned string from guessF is treated as a valid type by getAllInVolume and will be set as the blocks type
-- maxIter can be nil, and will default to 100
-- The rest of the arguments are passed straight to scanF
-- returns a list of tables with the format:
-- 	relX/Y/Z: The position of the scanned block relative to the geolyzer (in absolute coordinates)
-- 	minHardness: The calculated minimum hardness of the block, given the blocks distance from the geolyzer
--	maxHardness: The calculated maximum hardness of the block, given the blocks distance from the geolyzer
-- 	guess: The guessed type returned by guessF for this block
function gu.getAllInVolume(scanF, guessF, maxIter, ...)--sX, sY, sZ, offsetX, offsetY, offsetZ, maxIter) -- TODO: refactor and rename both of these functions...
  local collectedData = {}

  maxIter = maxIter or 100

  local loopI = 0
  local running = true

  while running and loopI ~= maxIter do
    running = false
    loopI = loopI + 1

    local scanData = scanF(...)--volumeScan(sX, sY, sZ, offsetX, offsetY, offsetZ)
    for i, scanDatum in ipairs(scanData) do
      if not collectedData[i] then 
        collectedData[i] = {
          relPos = scanDatum.relPos,
          minHardness = -math.huge,
          maxHardness = math.huge,
          guess = "unknown"
        }
      end
      local cd = collectedData[i]

      cd.minHardness = math.max(cd.minHardness, scanDatum.minHardness)
      cd.maxHardness = math.min(cd.maxHardness, scanDatum.maxHardness)

      cd.guess = guessF(cd.minHardness, cd.maxHardness)

      if cd.guess == "unknown" then
--        print(string.format("unknown %02.2f  %02.2f  %s  %02.2f %02.2f", cd.minHardness, cd.maxHardness, cd.relPos, cd.relPos:len(), gu.maxDeviationFromDistance(cd.relPos:len())))
--        print(string.format("        %02.2f  %02.2f  %02.2f", cd.maxHardness - cd.minHardness, gu.maxDeviationFromDistance(cd.relPos:len()), gu.maxDeviationFromDistance(cd.relPos:len())*2))
        running = true
      end

      --[[ Redundant if in order to more easily comment out printing
      local dist = cd.relPos:len() --gu.distance(cd.relX, cd.relY, cd.relY)--math.sqrt(cd.relX*cd.relX + cd.relY*cd.relY + cd.relZ*cd.relZ)
			if cd.guess ~= "unknown" then 
				print(string.format("% 2d  (% 3d, % 3d, % 3d)   %11s   %2f.2", loopI, cd.relX, cd.relY, cd.relZ, cd.guess, dist))
			end--]]
    end
  end

--  print("Number of scans done:", loopI)

  return collectedData
end





return gu

--[[
MIT License

Copyright (c) 2020 weakman54 (enkiigm@gmail.com)

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