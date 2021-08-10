--- === Emojis ===
---
--- Let users choose kanjis by name/keyword

-- based on the emoji's chooser spoon by Adriano de Luzio
-- https://github.com/aldur/dotfiles/tree/master/osx/hammerspoon/Spoons/Emojis.spoon

local obj = {}
obj.__index = obj

-- luacheck: globals hs

-- Metadata
obj.name = "Kanjis"
obj.version = "1.0"
obj.author = "Adriano Di Luzio <adrianodl@hotmail.it>"
obj.author = "Daniel M German <dmg@turingmachine.org>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal function used to find our location, so we know where to load files from

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
obj.spoonPath = script_path()
obj.kanjisTablePath = obj.spoonPath .. "kanjis_json_lua.lua"

obj.choices = {}
obj.chooser = nil
obj.hotkey = nil

dofile(obj.spoonPath .. "/table.lua")

local wf = hs.window.filter.defaultCurrentSpace

function obj.callback(choice)
    if not choice then return end

    local lastApplication = nil
    local lastFocused = wf:getWindows(wf.sortByFocusedLast)
    if #lastFocused > 0 then
        lastFocused[1]:focus()
        lastApplication = lastFocused[1]:application()
    end

    if lastApplication ~= nil and hs.fnutils.contains(
        {'com.qvacua.VimR', 'com.googlecode.iterm2', 'com.apple.Safari'}, lastApplication:bundleID()
    ) then
        -- Some applications do not seem to handle "typing" kanjis.
        -- In those cases, we put them in the pasteboard, paste them, and then restore the status.
        local previousContent = hs.pasteboard.getContents()
        hs.pasteboard.setContents(choice.char)
        hs.eventtap.keyStroke({'cmd'}, 'v')
        hs.pasteboard.setContents(previousContent)
    else
        hs.eventtap.keyStrokes(choice.char)
    end
end


function obj:init()
   -- is the kanjis file available?
   -- loading the json file is extremely slow, so parse it and serialize it into a lua file
   print("Starting Kanjis Spoon...")
   local mod = nil
   local mod, err = table.load(obj.kanjisTablePath) -- luacheck: ignore
   if err then
      print("Kanjis Spoon: table's not here, generating it from json.")
      mod = nil
   end
   if not mod then
      self.choices = {}
      print("starting to read the file")
      for _, kanji in pairs(hs.json.decode(io.open(self.spoonPath .. "/kanji/kanji-all.json"):read())) do

         
         local subTexts = kanji.kanji .. " ^" ..  kanji.keyword .. " (" .. kanji.topreading  .. ") " .. kanji.strokes
         if kanji.components then
               subTexts = subTexts .. "\n" .. kanji.components:gsub("<br>", "\n")
         end
         print(subTexts)
         local char = kanji.kanji

         -- order by kanji
         local orderId = kanji.kanji

         table.insert(
            self.choices,
            {
               text = kanji.kanji,
               subText = subTexts,
               char = kanji.kanji,
               order = orderId
            }
         )
         
         ::continue::
      end
      table.sort(
         self.choices,
         function(a, b)
            return a["order"] < b["order"]
         end
      )
      
      print("Kanjis Spoon: Saving kanjis... ")
      table.save(self.choices, obj.kanjisTablePath) -- luacheck: ignore
      print("Kanjis Spoon: ... saved")
      mod = self.choices
   end

   -- we need to typeset the chooser
   local t = {}
   for k,v in pairs(mod) do
      t[k] = {
         text = hs.styledtext.new(v.text, { font={size=24},color={hex="#000000"}}),
         subText = hs.styledtext.new(v.subText, { font={size=24}}),
         char =   v.char,
         order = v.order
      }
   end
   self.choices = t
   
   self.chooser = hs.chooser.new(self.callback)
   self.chooser:rows(12)
   self.chooser:searchSubText(true)
   self.chooser:choices(self.choices)
   print("Kanjis Spoon: Startup completed")
end

function obj:kanji_chooser()
   print("Calling kanji chooser")
   if self.chooser:isVisible() then
      self.chooser:hide()
   else
      self.chooser:show()
   end
end


hs.hotkey.bind(
   {"cmd", "alt", "ctrl"}, "K",
   function() obj:kanji_chooser()
end)



return obj
