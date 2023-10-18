require("lib.lua-ecs.ECS_concat")




local Component = ECS.Component
local System = ECS.System
local Query = ECS.Query
local World = ECS.World

local Position = Component({
    x = 0,
    y = 0,
    z = 0
})

local Color = Component({
    r = 0,
    g = 0,
    b = 0
})

function Color:getRandomColor()
    return Color({
        r = math.random(),
        b = math.random(),
        g = math.random()
    })
end

local Velocity = Component({vx = 0, vy = 0})

local Accelerate = Component(0)

local Width = Component(0)

local Height = Component(0)

local Radius = Component(0)


local BallRenderSystem = System("render", 1, Query.All(Position, Radius, Color), function (self)
    self:Result():ForEach(function(entity)
        local position = entity[Position]
        local radius = entity[Radius].value
        local color = entity[Color]
        love.graphics.setColor(color.r, color.g, color.b)
        love.graphics.circle("fill", position.x, position.y, radius)
    end)
end)

local MovableSystem = System('process', 1, Query.All(Velocity), function (self, time)
    local delta = time.DeltaFixed
 
    for i, entity in self:Result():Iterator() do
       local velocity = entity[Velocity]
 
       local position = entity[Position]
       position.x = position.x + velocity.vx * delta
       position.y = position.y + velocity.vy * delta
       position.z = position.z + velocity.vx * delta
    end
end)


local WindowBorderWithCircleCollisionDetectionSystem = System("process", 1, Query.All(Position, Velocity, Radius), function (self)
    local st_x = WindowBorderRectangle[Position].x
    local st_y = WindowBorderRectangle[Position].y
    local en_x = st_x + WindowBorderRectangle[Width].value
    local en_y = st_y + WindowBorderRectangle[Height].value
    self:Result():ForEach(function (entity)

        local position = entity[Position]
        local velocity = entity[Velocity]
        local radius = entity[Radius].value

        if position.x - radius <= st_x or position.x + radius >= en_x then
            velocity.vx = velocity.vx * -1
        end
        if position.y - radius <= st_y or position.y + radius >= en_y then
            velocity.vy = velocity.vy * -1
        end
        
    end)
end)


function love.load()
    GameWorld = World()
    GameWorld:AddSystem(BallRenderSystem)
    GameWorld:AddSystem(MovableSystem)
    GameWorld:AddSystem(WindowBorderWithCircleCollisionDetectionSystem)
    WindowBorderRectangle =
        GameWorld:Entity(
            Position(0, 0),
            Width(love.graphics.getWidth()),
            Height(love.graphics.getHeight())
        )

    Balls = {}
    for i = 0, 10 do
        local r = math.random(10, 50)
        local v = math.random(10, 100)
        local x = math.random(r + 1, love.graphics.getWidth()  - r - 1)
        local y = math.random(r + 1, love.graphics.getHeight() - r - 1)
        table.insert(
            Balls,
            GameWorld:Entity(
                Radius({value = r}), 
                Position({x = x, y = y}),
                Velocity({vx = v, vy = v}),
                Color:getRandomColor()
            )
        )
    end
    Frames = 0
end


function love.update()
    GameWorld:Update("process", love.timer.getTime())
end

function love.draw()
    GameWorld:Update("render", love.timer.getTime())
end