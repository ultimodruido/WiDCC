local Loco = { }
Loco.__index = Loco

function Loco.new(pin_pwm, pin_dir, pin_light_front, pin_light_rear)
  local self = setmetatable ( { } , Loco )
  self.pin_pwm = pin_pwm
  pwm.setup(self.pin_pwm, 1000, 0)
  self.pin_dir = pin_dir
  gpio.mode(self.pin_dir, gpio.OUTPUT, gpio.FLOAT)
  self.pin_light_front = pin_light_front
  gpio.mode(self.pin_light_front, gpio.OUTPUT, gpio.FLOAT)
  self.pin_light_rear = pin_light_rear
  gpio.mode(self.pin_light_rear, gpio.OUTPUT, gpio.FLOAT)
  self.error = 1
  self.speed = 0
  self.speed_target = 0
  self.speed_update_start = 0
  self.direction = 0
  self.light = 0
  return self
end

function Loco:getStatus( )
  return self.speed, self.direction, self.light, self.error
end

function Loco:setLight(l_val)
  self.light = l_val
  if self.light then
    if self.direction then
      -- front on rear off
      gpio.write(self.pin_light_front, gpio.HIGH)
      gpio.write(self.pin_light_rear, gpio.LOW)
    else
      -- front off rear on
      gpio.write(self.pin_light_front, gpio.LOW)
      gpio.write(self.pin_light_rear, gpio.HIGH)
    end
  else
    -- disable both pins
    gpio.write(self.pin_light_front, gpio.LOW)
    gpio.write(self.pin_light_rear,  gpio.LOW)
  end
  return nil
end
 
function Loco:setDirection(d_val)
  -- change direction only if not moving
  if self.speed == 0 then
    self.direction = d_val
    if self.direction == 0 then
      gpio.write(self.pin_dir, gpio.LOW)
    else
      gpio.write(self.pin_dir, gpio.HIGH)
    end
    -- update lights direction
    Loco:setLight(self.light)
  end
end

function Loco:clearSpeed( )
  self.speed_target = 0
  self.speed = 0
  pwm.stop(self.pin_pwm)
  return nil
end

function Loco:setSpeed(s_val)
  self.speed_target = s_val
  self.speed_update_start = self.speed
  if self.speed = 0 then
    pwm.start(self.pin_pwm)
  end
  tmr.stop(0)
  tmr.alarm(0, 100, Loco:updateSpeed( ) )
end

function Loco:updateSpeed( )