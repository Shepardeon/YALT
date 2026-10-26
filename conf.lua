_RELEASE_MODE = not (os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' and arg[2] == 'debug')

if not _RELEASE_MODE then
    require("lldebugger").start()

    local loveErrorhandler = love.errorhandler

    function love.errorhandler(msg)
        if lldebugger then
            error(msg, 2)
        else
            return loveErrorhandler(msg)
        end
    end
end

function love.conf(t)
    t.console = not _RELEASE_MODE
    t.title = "Love Template"
    t.window.width = 640
    t.window.height = 360
end
