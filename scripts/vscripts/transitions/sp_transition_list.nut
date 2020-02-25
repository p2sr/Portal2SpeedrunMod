/*
This file is a replacement of an original transition script. Apparently it's included in every map with name
starting with "sp", even if the original map file doesn't contain it. This makes it a nice way to hook your
own code into the game (singleplayer only, unfortunately, but I imagine there's something similar for coop).
*/

//Including custom scripts.
DoIncludeScript("speedrunmod", self.GetScriptScope())

//Including the original script, preserving its original form.
local originalScriptPath = "..\\..\\..\\update\\scripts\\vscripts\\transitions\\sp_transition_list.nut";
DoIncludeScript(originalScriptPath, self.GetScriptScope());