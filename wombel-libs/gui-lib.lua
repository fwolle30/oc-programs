
local component = require("component");
local text = require("text");
local colors = require("colors");
local keyboard = require("keyboard");

local gpu = nil;
local scrW, scrH = nil, nil;

-- Classes --

-- Widget --

local Widget = {x = 0, y = 0, h = 0, w = 0, parent = nil, children = {}};
Widget.__index = Widget;

function Widget:new(args)
    local inst = {};
    setmetatable(inst, self);
    self.__index = self;

    local defaults = {
        __index={
            parent=nil, 
            x = nil, 
            y = nil, 
            h = nil, 
            w = nil
        }
    }

    setmetatable(args, defaults);
    inst.x = args.x;
    inst.y = args.y;
    inst.h = args.h;
    inst.w = args.w;
    inst.parent = args.parent;
    inst.children = {};

    if (type(args.parent) == "table" and type(args.parent.addChild) == "function") then
        args.parent:addChild(inst);
    end

    return inst;
end

function Widget:addChild(child) 
    table.insert(self.children, child);
    child.parent = self;
end

function Widget:draw()
end

function Widget:handleEvent(event)
  if (type(self.children) == "table" and #self.children > 0) then
    for k = 1, #self.children do
      local child = self.children[k];
      if (type(child) == "table" and type(child.handleEvent) == "function") then
        child:handleEvent(event);
      end
    end
  end
end

-- Frame Widget --

local Frame = Widget:new{};

Frame.Direction = {
    horizontal = 1,
    vertical = 2
};

function Frame:new(args)
    local defaults = {
        __index = {
            parent = nil, 
            x = nil, 
            y = nil, 
            h = nil, 
            w = nil, 
            framed = false,
            direction = Frame.Direction.vertical,
            title = nil
        }
    }

    setmetatable(args, defaults);

    if (type(args.parent) == "nil") then
        if (type(args.x) == "nil") then
            args.x = 1;
        end

        if (type(args.y) == "nil") then
            args.y = 1;
        end 

        if (type(args.w) == "nil") then
            args.w = scrW;
        end

        if (type(args.h) == "nil") then
            args.h = scrH;
        end
    end

    local instArgs = {};
    for k,v in pairs(args) do
        instArgs[k] = v;
    end

    local inst = Widget:new(instArgs);
    setmetatable(inst, self);
    self.__index = self;    

    inst.direction = args.direction;
    inst.framed = args.framed;
    inst.title = args.title;

    return inst;
end

local number = 0;
function getNextNumber()
    number = number + 1;
    return number
end

function Frame:draw()
    if (self.framed) then    

        local edges = {'┌', '┐', '└', '┘'};        
        
        local char = gpu.get(self.x, self.y);
        if (char == '└' or char == '│' or  char == '├') then
            edges[1] = '├';
        elseif (char == '─' or char == '┬') then
            edges[1] = '┬';
        elseif (char == '┤' or char == '┼') then
            edges[1] = '┼';
        end

        
        char = gpu.get(self.x + self.w - 1, self.y);
        if (char == '┘' or char == '│' or char == '┤') then
            edges[2] = '┤';
        elseif (char == '─' or char == '┬') then
            edges[2] = '┬';
        elseif (char == '┼') then
            edges[2] = '┼';
        end    

        char = gpu.get(self.x, self.y + self.h - 1);
        if (char == '┘' or char == '┴') then
            edges[3] = '┴';
        elseif (char == '│' or char == '├') then
            edges[3] = '├';
        elseif (char == '┤' or char == '┼') then
            edges[3] = '┼';
        end    

        char = gpu.get(self.x + self.w - 1, self.y + self.h - 1);
        if (char == '┤') then
            edges[4] = '┤';
        elseif (char == '┴') then
            edges[4] = '┴';
        elseif (char == '┼') then
            edges[4] = '┼';
        end         
        
        for i = self.y,(self.y + self.h) - 1 do
            local ld = gpu.get(self.x, i);
            if (ld == ' ' or self.parent == nil) then
                ld = '│';
            end;

            gpu.set(self.x, i, ld);
        end

        for i = self.x,(self.x + self.w) - 1 do
            local ld = gpu.get(i, self.y);
            if (ld == ' ' or self.parent == nil) then
                ld = '─';
            end;

            gpu.set(i, self.y, ld);
        end 

        gpu.fill(self.x + 1 , self.y + 1, self.w - 2, self.h - 2, ' ');
        gpu.fill(self.x, self.y + self.h - 1, self.w, 1, '─');        
        gpu.fill(self.x + self.w - 1, self.y, 1, self.h, '│');

        gpu.set(self.x, self.y, edges[1]);
        gpu.set(self.x + self.w - 1, self.y, edges[2]);
        gpu.set(self.x, self.y + self.h - 1, edges[3]);
        gpu.set(self.x + self.w - 1, self.y + self.h - 1, edges[4]);

        if (type(self.title) ~= "nil") then
            local title = " " .. self.title .. " ";
            local titleLength = math.min(title:len() + 2, self.w);
            local titlePos = math.floor((self.w - titleLength) / 2);

            local fg, fgp = gpu.getForeground();
            local bg, bgp = gpu.getBackground();

            gpu.setBackground(fg, fgp);
            gpu.setForeground(bg, bgp);

            gpu.set(self.x + titlePos + 1, self.y, title:sub(1, title.length));

            gpu.setBackground(bg, bgp);
            gpu.setForeground(fg, fgp);
        end
    else
        gpu.fill(self.x, self.y, self.w, self.h, ' ');
    end

    if (type(self.children) == "table" and #self.children > 0) then
        local offsetX = 0;
        local offsetY = 0;  

        if (self.framed) then
            offsetX = 1;
            offsetY = 1;
        end

        local freeHeight = self.h;
        local freeWidth = self.w;
        local unmanaged = 0;
        local frames = 0;

        if (self.framed) then
            freeHeight = freeHeight - 2;
            freeWidth = freeWidth - 2;
        end

        for _, v in ipairs(self.children) do
            if (self.direction == Frame.Direction.vertical and v.h > 0) then
                freeHeight = freeHeight - v.h;
            elseif (self.direction == Frame.Direction.horizontal and v.w > 0) then
                freeWidth = freeWidth - v.w;
            else
                unmanaged = unmanaged + 1;
            end
        end

        local height = math.floor((freeHeight) / unmanaged);
        local width = math.floor((freeWidth) / unmanaged);

        for i, v in ipairs(self.children) do
            v.x = self.x + offsetX;
            v.y = self.y + offsetY;

            if (self.framed and v.framed and i == 1) then
                v.x = v.x - 1;
                v.y = v.y - 1;
            end
            
            if (self.direction == Frame.Direction.horizontal) then
                v.h = self.h - 2;

                if (self.framed and v.framed) then
                    v.h = self.h;
                end
    
                if (v.w == 0) then
                    v.w = width + 1;

                    while (v.w + offsetX > self.w - 1) do
                        v.w = v.w - 1;
                    end
                end 

                if (self.framed and v.framed and i > 1) then
                    v.y = v.y - 1;
                end

                if (i > 1 and self.framed and v.framed and self.children[i - 1].framed) then
                    v.x = v.x - 1;
                end

                if (i < #self.children and self.framed and v.framed) then
                    offsetX = offsetX - 1;
                end

                if (v.framed and self.framed and i == #self.children) then
                    v.w = v.w + 2;
                end

                offsetX = offsetX + v.w;
            elseif (self.direction == Frame.Direction.vertical) then
                if (v.h == 0) then
                    v.h = height + 1;

                    while (v.h + offsetY > self.h - 1) do
                        v.h = v.h - 1;
                    end
                end
    
                v.w = self.w - 2;
                if (self.framed and v.framed) then
                    v.w = self.w;
                end

                if (self.framed and v.framed and i > 1) then
                    v.x = v.x - 1;
                end      
                
                if (i > 1 and self.framed and v.framed and self.children[i - 1].framed) then
                    v.y = v.y - 1;
                end   

                if (i < #self.children and self.framed and v.framed) then
                    offsetY = offsetY - 1;
                end                
                
                if (v.framed and self.framed and i == #self.children) then
                    v.h = v.h + 2;
                end

                offsetY = offsetY + v.h;
            end

            v:draw();
        end
    end
end

-- Label Class --

local Label = Widget:new{};

function Label:new(args) 
    local defaults = {
        __index = {
            parent = nil, 
            x = nil, 
            y = nil, 
            h = nil, 
            w = nil, 
            text = nil
        }
    }

    setmetatable(args, defaults);

    if (args.text) then
        w = args.text:len();
    end

    if (type(args.h) == "nil") then
        args.h = 1;
    end

    local instArgs = {};
    for k,v in pairs(args) do
        instArgs[k] = v;
    end

    local inst = Widget:new(instArgs);
    setmetatable(inst, self);
    self.__index = self;

    inst.text = args.text;

    return inst;
end

function Label:draw()
    local length = self.w;

    gpu.set(self.x, self.y, text.padRight(self.text:sub(1, length), length));
end

-- ValueDisplay Widget --
local ValueDisplay = Widget:new{};

ValueDisplay.Align = {
    Left = 0,
    Right = 1
}

function ValueDisplay:new(args)
    local defaults = {
        __index = {
            parent = nil, 
            x = nil, 
            y = nil, 
            h = nil, 
            w = nil, 
            label = nil,
            labelWidth = 0,
            value = nil,
            align = ValueDisplay.Align.Left,
            prefix = nil,
            suffix = nil
        }
    }

    setmetatable(args, defaults);

    if (args.label and args.labelWidth <= 0) then
        args.labelWidth = args.label:len();
    end

    if (args.value and type(args.w) == "nil") then
        args.w = args.value:len();
        
        if (args.prefix) then
            args.w = args.w + args.prefix:len();
        end

        if (args.suffix) then
            args.w = args.w + args.suffix:len();
        end        
    end

    local instArgs = {};
    for k,v in pairs(args) do
        instArgs[k] = v;
    end

    local inst = Widget:new(instArgs);
    setmetatable(inst, self);
    self.__index = self;

    inst.label = args.label;
    inst.labelWidth = args.labelWidth;
    inst.value = args.value;
    inst.align = args.align;
    inst.prefix = args.prefix;
    inst.suffix = args.suffix;

    return inst;
end

function ValueDisplay:draw()
    local length = self.w - self.labelWidth;
    local valLength = length;

    local display = text.padRight(self.label:sub(1, self.labelWidth), self.labelWidth);
    local val = "";

    if (self.prefix) then
        val = val .. self.prefix;
        valLength = valLength - self.prefix:len();
    end

    val = val .. self.value:sub(1, valLength);

    if (self.suffix) then
        valLength = valLength - self.suffix:len();
        val = val:sub(1, valLength) .. self.suffix;
    end

    if (self.align == ValueDisplay.Align.Right) then
        val = text.padLeft(val, length);
    else
        val = text.padRight(val, length);
    end
    
    display = display .. val;

    gpu.set(self.x, self.y, display);
end

-- Progress Widget --
local Progress = Widget:new{};

Progress.Align = {
    horizontal = 1,
    vertical = 2
}

function Progress:new(args)
    local defaults = {
        __index = {
            parent = nil, 
            x = nil, 
            y = nil, 
            h = nil, 
            w = nil, 
            align = Progress.Align.horizontal,
            maxValue = 100,
            value = 0,
            color = colors.white,
            bgcolor = colors.black
        }
    }

    setmetatable(args, defaults);

    if (args.align == Progress.Align.horizontal and type(args.h) == "nil") then
        args.h = 1;
    elseif (args.align == Progress.Align.vertical and type(args.w) == "nil") then
        args.w = 1;
    end

    local instArgs = {};
    for k,v in pairs(args) do
        instArgs[k] = v;
    end

    local inst = Widget:new(instArgs);
    setmetatable(inst, self);
    self.__index = self;

    inst.direction = args.direction;
    inst.maxValue = args.maxValue;
    inst.value = args.value;
    inst.color = args.color;
    inst.bgcolor = args.bgcolor;

    return inst;
end

function Progress:draw()
    local height = self.h;
    local width = self.w;
    local progress = math.min(self.value, self.maxValue) / self.maxValue;
    local progWidth = width * 8 * progress;
    local mod = progWidth % 8;
    local progVal = math.floor(progWidth / 8);
    local modTable = {"▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"};

    local pbar = {};
    for i = 1, width do
        if (i == progVal + 1 and math.floor(mod) > 0) then
            pbar[i] = modTable[math.floor(mod)];
        elseif (i <= progVal) then
            pbar[i] = modTable[8];
        else
            pbar[i] = " ";
        end
    end

    gpu.setDepth(4);
    local bg, bgp = gpu.getBackground();
    local fg, fgp = gpu.getForeground();
    local depth = gpu.getDepth();
    
    if (depth > 1) then
        gpu.setBackground(self.bgcolor, true);
        gpu.setForeground(self.color, true);
    end

    for t = self.y, self.y + height - 1 do
        gpu.set(self.x , t, table.concat(pbar));
    end
    gpu.setBackground(bg, bgp);
    gpu.setForeground(fg, fgp);
end

-- Menu --
local Menu = Widget:new{};

function Menu:new(args)
  local defaults = {
    __index = {
        parent = nil, 
        x = nil, 
        y = nil, 
        h = nil, 
        w = nil,
        items = nil,
        activeItem = nil
    }
  }

  setmetatable(args, defaults);

  args.h = 1;
  args.items = {};
  args.activeItem = 1;

  local instArgs = {};
  for k,v in pairs(args) do
      instArgs[k] = v;
  end

  local inst = Widget:new(instArgs);
  setmetatable(inst, self);
  self.__index = self;

  inst.items = args.items;
  inst.activeItem = args.activeItem;

  return inst;
end;

function Menu:draw()
  local bg = {gpu.getBackground()};
  local fg = {gpu.getForeground()};

--  gpu.setForeground(table.unpack(bg));
--  gpu.setBackground(table.unpack(fg));

--  gpu.set(self.x, self.y, text.padRight('  Menu Punkt', self.w));

--  gpu.setForeground(table.unpack(fg));
--  gpu.setBackground(table.unpack(bg));

  for k = 0, #self.items - 1 do
    if ((k + 1) == self.activeItem) then
      gpu.setForeground(table.unpack(bg));
      gpu.setBackground(table.unpack(fg));
    end;

    local item = self.items[k+1];
    label = "  " .. item.label;

    gpu.set(self.x, self.y + k, text.padRight(label, self.w));

    gpu.setForeground(table.unpack(fg));
    gpu.setBackground(table.unpack(bg));
  end;
end;

function Menu:addMenuEntry(label, callback)
  local item = {
    label = label,
    callback = callback
  }

  table.insert(self.items, item);
end;

function Menu:handleEvent(event)
  if (event[1] == "key_down") then
    local oldPos = self.activeItem;

    if (event[4] == keyboard.keys.up) then
      self.activeItem = math.max(1, self.activeItem - 1);
    elseif (event[4] == keyboard.keys.down) then
      self.activeItem = math.min(#self.items, self.activeItem + 1);
    elseif (event[4] == keyboard.keys.enter) then
      local item = self.items[self.activeItem];
      if (type(item) == "table" and type(item.callback) == "function") then
        item:callback();
      end
    end

    if (oldPos ~= self.activeItem) then
      self:draw();
    end
  end
end

-- init method --
function initLib()
  gpu = component.gpu;
  scrW, scrH = gpu.getResolution();
end

-- export module --
return {
  initLib = initLib,
  Widget = Widget,
  Frame = Frame,
  Label = Label,
  ValueDisplay = ValueDisplay,
  Progress = Progress,
  Menu = Menu
}
