require 'gosu'

# https://leanpub.com/developing-games-with-ruby/read

class Tutorial < Gosu::Window
	def initialize
    # create a 1280 x 720 pixel large window
    super 1280, 720
    # title bar
    self.caption = "Game"
    @background_image = Gosu::Image.new("underwater2.png", :tileable => true)
    @player = Player.new
    @shark = Shark.new
    @player.warp(640, 360)
    @seashell_anim = Gosu::Image.load_tiles("seashell.png", 40, 38)
    @health_powerup_animation = Gosu::Image.load_tiles("health_powerup.png", 50, 54)
    @seashells = Array.new
    @powerups = Array.new
    @font = Gosu::Font.new(20)
    @doctor = Doctor.new
    @bomb = Bomb.new
    @counter = 0
  end

  # called 60 times per second
  # contain main game logic
    # ex: moving objects, testing for collisions
  def update
    if Gosu.button_down? Gosu::KB_LEFT or Gosu::button_down? Gosu::GP_LEFT
      @player.turn_left
    end
    if Gosu.button_down? Gosu::KB_RIGHT or Gosu::button_down? Gosu::GP_RIGHT
      @player.turn_right
    end
    if Gosu.button_down? Gosu::KB_UP or Gosu::button_down? Gosu::GP_BUTTON_0
      @player.accelerate
    end
    @player.move
    @player.collect_seashells(@seashells)
    @player.collect_powerups(@powerups)
    @player.hit_shark(@shark)
    @player.visit_doctor(@doctor)
    @player.hit_bomb(@bomb)
    @counter += 1

    if rand(100) < 4 and @seashells.size < 50
      @seashells.push(Seashell.new(@seashell_anim))
    end

    # every 10 seconds there's a 50% chance a new health powerup will appear
    # if there are none already on the screen
    if @counter % 600 == 0 and @powerups.size < 1 and rand(100) < 50
      @powerups.push(HealthPowerup.new(@health_powerup_animation))
    end

    # every 5 seconds move the bomb
    if @counter % 300 == 0
      @bomb.move
    end

    @shark.move_left

  end

  # called 60 times per second
  # should contain code to redraw the scene
  # no game logic
  def draw
    @player.draw
    @shark.draw
    @doctor.draw
    @bomb.draw
    # upper left corner drawn at (0,0) with z ordering of 0
    # higher z = drawn on top of lower z
    @background_image.draw(0, 0, ZOrder::BACKGROUND)
    @seashells.each { |seashell| seashell.draw }
    @powerups.each { |powerup| powerup.draw }
    @font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @font.draw("Health: #{@player.health}", 10, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def button_down(id)
    if id == Gosu::KB_ESCAPE
      close
    else
      super
    end
  end

end

class Doctor
  attr_reader :x, :y
  def initialize
    @image = Gosu::Image.new("doctor.png")
    @x = 1000
    @y = 400
  end

  def draw
    # puts the center at (x,y) instead of the upper corner
    # makes collisions more central and accurate
    @image.draw_rot(@x, @y, ZOrder::PLAYER, 0)
  end
end

class Bomb
  attr_reader :x, :y

  def initialize
    @image = Gosu::Image.new("bomb.png")
    @x = rand * 1200
    @y = rand * 700
  end

  def draw
    @image.draw_rot(@x, @y, ZOrder::PLAYER, 0)
  end

  def move
    @x = rand * 1200
    @y = rand * 700
  end

  def update
    @image.draw_rot(@x, @y, ZOrder::PLAYER, 0)
  end
end

class Shark
  attr_reader :x, :y

  def initialize
    @image = Gosu::Image.new("shark2.png")
    @x = 100
    @y = 200
  end

  def move_left
    @x -= 5
    @y += Math.sin(10 * Gosu.milliseconds / 700) * 3
    @x %= 1280
  end

  def draw
    @image.draw_rot(@x, @y, ZOrder::PLAYER, 0)
  end

  def update
    @image.draw_rot(@x, @y, ZOrder::PLAYER, 0)
  end

end

class Player
  attr_reader :x, :y
  def initialize
    @image = Gosu::Image.new("octopus.png")
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @score = 0
    @health = 100
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end

  def accelerate
    # moves at 0.5 pixels per frame at an angle of @angle
    @vel_x += Gosu.offset_x(@angle, 0.5)
    @vel_y += Gosu.offset_y(@angle, 0.5)
  end

  def move
    @x += @vel_x
    @y += @vel_y
    @x %= 1280
    @y %= 720

    @vel_x *= 0.95
    @vel_y *= 0.95

  end

  def draw
    # puts the center of the image at (x,y)
    # z = 1 = drawn over the background
    @image.draw_rot(@x, @y, ZOrder::SEASHELLS, @angle)
  end

  def score
    @score
  end

  def health
    @health
  end

  def hit_shark(shark)
    if Gosu.distance(@x, @y, shark.x, shark.y) < 50
      @health -= 1
    end
  end

  def visit_doctor(doctor)
    if Gosu.distance(@x, @y, doctor.x, doctor.y) < 50
      @score -= 1
      @health += 1
    end
  end

  def hit_bomb(bomb)
    if Gosu.distance(@x, @y, bomb.x, bomb.y) < 50
      @font.draw("GAME OVER", 640, 360, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end
  end

  def collect_seashells(seashells)
    seashells.reject! do |seashell| 
      if Gosu.distance(@x, @y, seashell.x, seashell.y) < 35
        @score += 10
        true
      else
        false
      end
    end
  end

  def collect_powerups(powerups)
    powerups.reject! do |powerup|
      if Gosu.distance(@x, @y, powerup.x, powerup.y) < 35
        @health += 50
        true
      else
        false
      end
    end
  end
end

module ZOrder
  BACKGROUND, SEASHELLS, PLAYER, UI = *0..3
end

class Seashell
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @x = rand * 1200
    @y = rand * 700
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw_rot(@x, @y, 0, 50 * Math.sin(Gosu.milliseconds / 133.7))
    # img.draw(@x - img.width / 2.0, @y - img.height / 2.0, ZOrder::SEASHELLS, 1, 1, @color, :add)
  end
end

class HealthPowerup
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @x = rand * 1200
    @y = rand * 700
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw_rot(@x, @y, 0, 50 * Math.sin(Gosu.milliseconds / 133.7))
  end
end

# create a window and call its show method
# main loop
Tutorial.new.show


















