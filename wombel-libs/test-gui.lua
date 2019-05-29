local gui = require 'gui-lib'

local component = require('component');
local os = require('os');
local term = require('term');
local io = require('io');
local colors = require('colors');
local event = require("event");

require("utils-math");

component.gpu.setResolution(50, 16);

gui.initLib();

local fm = gui.Frame:new{framed = true, direction = gui.Frame.Direction.horizontal};

local sidePanel = gui.Frame:new{parent = fm, framed = true, w = 15, title = "Menu"};
local mainFrame = gui.Frame:new{parent = fm, framed = true};

local contentFrame = gui.Frame:new{parent = mainFrame, framed = true, title = "Content", direction = gui.Frame.Direction.horizontal};
local debugPanel = gui.Frame:new{parent = mainFrame, framed = true, h = 8, title = "Debug"};

local contentLabelPanel = gui.Frame:new{parent = contentFrame, w = 10, framed = false};
local contentPanel = gui.Frame:new{parent = contentFrame, framed = false};

local energyLabel = gui.Label:new{parent = contentLabelPanel, text = " Energy"};
local energyBar = gui.Progress:new{parent = contentPanel, maxValue = 200, value = 0, color = colors.red, bgcolor = colors.gray};

local fuelLabel = gui.Label:new{parent = contentLabelPanel, text = " Fuel"};
local fuelBar = gui.Progress:new{parent = contentPanel, maxValue = 100, value = 100, color = colors.yellow, bgcolor = colors.gray};

local menu = gui.Menu:new{parent = sidePanel}

local running = true;

function test1() end;
function test2() end;
function test3() end;
function test4() end;
function test5() end;
function exit() running = false; end;

menu:addMenuEntry("Test 1", test1);
menu:addMenuEntry("Test 2", test2);
menu:addMenuEntry("Test 3", test3);
menu:addMenuEntry("Test 4", test4);
menu:addMenuEntry("Test 5", test5);
menu:addMenuEntry("exit", exit);

fm:draw();

function onEvents(...)
  local event = {n=select('#', ...), ...};
  fm:handleEvent(event);
end;

event.listen("key_down", onEvents);

--term.read();

while running do
  os.sleep(0.05);
end;

event.ignore("key_down", onEvents);
term.clear();