--Sacred AHK version 9.7 | easy to gey the code  
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local razonDeBan = [[You have been banned from this experience.

Reason: Violating Community Standards - Exploiting (Error Code: 267)
Ban Expiration: Permanent
Moderator ID: 1928374]]

task.wait(0.8)
player:Kick(razonDeBan)
