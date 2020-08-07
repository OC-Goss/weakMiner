
local robot = require("robot")


local roboUtil = {}

function roboUtil.dumpInventory(startSlot, endSlot)
  startSlot = startSlot or 1
  endSlot = endSlot or robot.inventorySize()

  if startSlot > endSlot then
    local t = startSlot
    startSlot = endSlot
    endSlot = t
  end

  for slotI=startSlot, endSlot do
    robot.select(slotI)
    robot.drop()
  end
end



return roboUtil