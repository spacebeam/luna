#!/usr/bin/env luajit
--
-- Spawn nodes of daemons — all operations run using command luna.
--
local tools = require("spacebeam.tools")
local messages = require("spacebeam.messages")
local version = require("spacebeam.version")
local options = require("spacebeam.options")
-- third-party lua libraries
local yaml = require("spacebeam.lib.yaml")
local argparse = require("argparse")
local socket = require("socket")
local uuid = require("uuid")
-- init random seed
uuid.randomseed(socket.gettime()*10000)
-- Session UUID
local session_uuid = uuid()

-- Spaceboard Erlang/OTP release
local release = "/_rel/spaceboard_release/bin/spaceboard_release"
-- *nix spawning pool
local spool = "/var/spool"
-- CLI argument parser
local parser = argparse() {
   name = "luna",
   description = "Spacebeam workspace (luna) command line tool.",
   epilog = "Remember, as your units grow in number, you must spawn more nodes to control them."
}
parser:option("-u --unit", "name, uuid or hash", false)
parser:option("-x --execute", "exec string", "")
parser:option("-d --directory", "Sandbox directory", "/opt/sandbox/")
parser:command_target("command")
-- Build its node or unit sandbox from SIF file
parser:command("build")
-- Start and stop encapsulated instance of userspace
parser:command("start")
parser:command("stop")
parser:command("run")
parser:command("status")
parser:command("version")

local args = parser:parse()
local run = "singularity run --writable " .. args['directory']
local start = "singularity instance start --writable " .. args['directory']
local stop = "singularity instance stop " .. args['directory']
local build = "singularity build --sandbox"
local git_clone_spaceboard = "git clone https://github.com/spacebeam/spaceboard"
local spaceboard = "/opt/spaceboard/"

if args['command'] == 'build' then
    if args['unit'] then
        local file = "/opt/luna/include/"..args['unit'] .. ".yml"
        local content = tools.read_file(file)
        local unit = yaml.parse(content)
        print('Building ' .. args['unit'] .. ' into ' .. args['directory'])
        if unit['fetch'] == 'git' then
            os.execute("git clone " .. unit['url'] .. " /var/spool/luna/".. unit['name'])
        else print('let this crash')
        end
        -- build singularity container
        os.execute(build .. ' ' ..args['directory'] .. unit['name'] ..
        ' ' .. spool .. '/luna/' .. unit['name'] .. '/' .. unit['name'] .. '.sif')
        print('Done... ' .. messages[math.random(#messages)])
    else
        os.execute("mkdir " .. spool .."/luna")
        -- fetch current index
        os.execute("git clone https://github.com/spacebeam/luna /opt/luna")
        -- build this node and prepare to fight
        os.execute(git_clone_spaceboard .. " " .. spaceboard)
        os.execute("curl -O https://erlang.mk/erlang.mk")
        os.execute("mv erlang.mk " .. spaceboard)
        os.execute("rm erlang.mk")
        os.execute("cd " .. spaceboard .. " && make all")
        print('Done... ' .. messages[math.random(#messages)])
    end
elseif args['command'] == 'start' then
    if args['unit'] then
        print('Starting unit ' .. args['unit'])
        os.execute(start .. args['unit'] .. " " .. args['unit'])
        print('Done... ' .. messages[math.random(#messages)])
    else
        os.execute(spaceboard .. release .. " start")
        print('Done... ' .. messages[math.random(#messages)])
    end
elseif args['command'] == 'stop' then
    if args['unit'] then
        print('Stoping unit ' .. args['unit'])
        os.execute(stop .. args['unit'] .. " " .. args['unit'])
        print('Done... ' .. messages[math.random(#messages)])
    else
        os.execute(spaceboard .. release .. " stop")
        print('Done... ' .. messages[math.random(#messages)])
    end
elseif args['command'] == 'run' then
    if args['unit'] then
        if args['execute'] then
            os.execute(run .. args['unit'] .. ' ' .. args['execute'])
        else
            os.execute(run .. args['unit'])
        end
    else
        print('Did you forget about the ' .. messages[4])
    end
elseif args['command'] == 'status' then
    if args['unit'] then
        print('Getting the status of unit ' .. args['unit'] )
        -- status
        print('Done.. ' .. messages[math.random(#messages)])
    else
        print('Execution session ' .. session_uuid)
        os.execute("singularity instance list")
        os.execute(spaceboard .. release .. " ping")
    end
elseif args['command'] == 'version' then
    print('luna version '..version)
else
    -- do something else
    print(messages[1])
end
