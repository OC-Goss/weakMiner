# weakMiner
A miner program for use with OpenComputers mod


# Important notice
I use nibnav to keep track of the robot's position while mining. This position is reset each time the robot is restarted and will move out of sync if you move the robot through anything other than the nibnav move functions (analogous to the robot API move functions).

You will need to set the initial position of the robot manually currently. (See ``Pre run configuration`` below for instructions)

# Setup

## Robot hardware

### Needed components
(Note that some of these will be downgraded as I implement fallbacks for them not existing)

* Crafting upgrade - Is used to craft new picks
* Inventory Controller
* Generator upgrade - For extended trips, I'm working on making this optional
* Geolyzer
* Screen + Keyboard - For running the program, though if you can find a way to run it without these, they are otherwise not needed. I'm unsure if using print when there is no screen to output to works though...
* graphics card or APU - if using a screen
* at least one inventory upgrade, but my current build uses 3, and fill them out pretty quickly (with one "mining run" being 6400 blocks in volume). I usually use T1 Upgrade containers to fit these in

### Optional but useful components

* Chunkloader
* Hover upgrade (I'm not 100% sure how much this is needed, but I might add in code to handle not having this later)
* Experience upgrade - Greatly increases battery size and robot capability (mining speed) over time, very good at extending the range of the robot.

### Hardware
* T3 case - Might not be needed once I make some of the components optional.
* Memory can be pretty low (I've run the bot on one T2.5 stick). I will test more thoroughly to determine the minimum needed soon.
* I'm unsure about CPU, but I've always used a T3, could probably be lower.
* Same for HDD
* Graphics card or APU if using a screen
* Some way of communicating (wireless, Internet, linked) This is not used at the moment, but I will add in capabilities to specify logging functions at some point



## Pre run configuration
* Set the nibnav position and facing!! I usually set up a small script to do this for me, but to determine the correct position and facing I do this:
  * Stand behind the robot, facing the same way it does
  * Make sure to be looking at the robot
  * Open up the F3 menu
  * Go into the lua interpreter
  * Find the "Looking at" and "Facing:" values in the F3 menu
  * Copy these over into nibnav.setPosition([x], [y], [z], sides.[facing])
  * You will need to do this every time you restart the robot or move it through non-nibnav means.
* Read through the config options in miner.lua and make sure to set the variables to correct values for your use case (homePos and the directional vectors for trunk and branches). This is where you will set how much to mine, I recommend starting small and slowly building up the values so you can ensure everything is working correctly.
* Set up the home "base" with a charger pad and dump chest (and make sure to set the correct sides for those inventories in the config)



# Instructions for use
Home pos setup:
   Charger adjacent to homePos
   A Chest for dumping inventory between mining runs
    Optionally a chest for keeping needed materials for the robot (maintenance chest)

 Brief description of a run
 For each branch:
    do a pre-dig maintenance check
     ensure good pick durability. craft a new pick otherwise
      refuel
    mine down the "trunk" to the branch start position
    mine in  branchDir for scanChunkSize*branchDepth blocks
      each scanChunkSize blocks, do a scan and mine out the detected ores
    mine in -branchDir for scanChunkSize*branchDepth blocks, with its position shifted by shiftDir*scanChunkSize blocks
      each scanChunkSize blocks, do a scan and mine out the detected ores
    
  return to trunk
  return to home
  dump resources in dump chest


# Config options
(Nothing here yet)

# Changelog
(Nothing here yet)

# TODO
- [ ] add in optional waypoint positioning in order to not run away into eternity if the user forgets to config nibnav position before starting the miner
- [ ] check fuel and inventory levels during a run
- [ ] self refuel during a run
- [ ] Keep track of where we have mined already
- [ ] add in config for type of fuel
- [ ] Make components optional
- [ ] allow fuel to not be full stack (with a warning)
- [ ] allow specifying pick material in config
- [ ] allow specifying fuel material in config
- [ ] Log memory usage to determine minimum needed ram
- [ ] Add in optional logging
- [ ] Move config to its own file
- [ ] Move instructions out of the main file?
- [ ] Make prints optional
- [ ] Option to dig both sides of the trunk

## Maybes
- [ ] mining quota?
- [ ] add torches to reduce monster spawns?
- [ ] add in nice mining (putting down paths for the player)?
- [ ] add in trunk nice mining?
