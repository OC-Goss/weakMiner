# weakMiner
A miner program for use with OpenComputers mod


# Robot setup
memory can be pretty low (I've run the bot on one T2.5 stick)

# Instructions for use
Home pos setup:
   Charger adjacent to homePos
   A Chest for dumping inventory between mining runs
    Optionally a chest for keeping needed materials for the robot (maintenance chest)

 Brief description of a run
 For each branch:
    do a pre-dig maintenance check
     ensure good pick durability, otherwise craft a new pick
      refuel
    mine down the "trunk" to the branch start position
    mine in  branchDir for scanChunkSize*branchDepth blocks
      each scanChunkSize blocks, do a scan and mine out the detected ores
    mine in -branchDir for scanChunkSize*branchDepth blocks, with it's position shifted by shiftDir*scanChunkSize blocks
      each scanChunkSize blocks, do a scan and mine out the detected ores
    
  return to trunk
  return to home
  dump resources in dump chest


# Config options

# Changelog


# TODO
- [ ] add in optional waypoint positioning in order to not run away into eternity if user forgets to config nibnav position before starting miner
- [ ] check fuel and inventory levels during run
- [ ] self refuel during run
- [ ] Keep track of where we have mined already
- [ ] add in config for type of fuel
- [ ] Make components optional
- [ ] allow fuel to not be full stack (with a warning)
- [ ] allow specifying pick material in config
- [ ] allow specifying fuel material in config
- [ ] Log memory usage to determine minimum needed ram
- [ ] Add in optional logging
- [ ] Move config to it's own file
- [ ] Move instructions out of main file?
- [ ] Make prints optional
- [ ] Option to dig both sides of the trunk

## Maybes
- [ ] mining quota?
- [ ] add torches to reduce monster spawns?
- [ ] add in nice mining (putting down paths for the player)?
- [ ] add in trunk nice mining?

