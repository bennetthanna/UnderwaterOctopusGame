require 'gosu'

# TO DO: make game over screen and possibly start game screen
# TO DO: add logic for when health goes below 0

class Tutorial < Gosu::Window
	def initialize
    # create a 1280 x 720 pixel large window
    super 1280, 720
    # title bar
    self.caption = "Octopus Adventure"
    @game_over_screen = GameOverScreen.new
    @game_screen = GameScreen.new
    @game_over = false
    @player = Player.new
    @shark = Shark.new
    @player.warp(640, 360)
    @seashell_animation = Gosu::Image.load_tiles("seashell.png", 40, 38)
    @health_powerup_animation = Gosu::Image.load_tiles("health_powerup.png", 50, 54)
    @double_points_animation = Gosu::Image.load_tiles("double_points.png", 50, 50)
    @magnet_powerup_animation = Gosu::Image.load_tiles("magnet.png", 50, 53)
    @seashells = Array.new
    @powerups = Array.new
    @doctor = Doctor.new
    @bomb = Bomb.new
    @counter = 0
    @font = Gosu::Font.new(20)
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
    @player.collect_powerups(@powerups, @seashells)
    @player.hit_shark(@shark)
    @player.visit_doctor(@doctor)
    @player.hit_bomb(@bomb)
    @counter += 1
    @powerups.each { |powerup| powerup.update }

    if rand(100) < 4 and @seashells.size < 35
      @seashells.push(Seashell.new(@seashell_animation))
    end

    # every 10 seconds there's a 50% chance a new health powerup will appear
    # if there are none already on the screen
    if @counter % 600 == 0 and (@powerups.include?(HealthPowerup) != true) and rand(100) < 50
      @powerups.push(HealthPowerup.new(@health_powerup_animation))
    end

    if @counter % 1200 == 0 and (@powerups.include?(DoublePointsPowerup) != true) and rand(100) < 50
      @powerups.push(DoublePointsPowerup.new(@double_points_animation))
    end

    if @counter % 1800 == 0 and (@powerups.include?(MagnetPowerup) != true) and rand(100) < 30
      @powerups.push(MagnetPowerup.new(@magnet_powerup_animation))
    end

    # every 5 seconds move the bomb
    if @counter % 300 == 0
      @bomb.move
    end

    @shark.move_left

    if @player.health < 0 or Gosu.distance(@player.x, @player.y, @bomb.x, @bomb.y) < 50
      @game_over = true
    end
  end

  # called 60 times per second
  # should contain code to redraw the scene
  # no game logic
  def draw
    @player.draw
    @shark.draw
    @doctor.draw
    @bomb.draw
    @seashells.each { |seashell| seashell.draw }
    @powerups.each { |powerup| powerup.draw }
    if @game_over == false
      @game_screen.draw
      @font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      @font.draw("Health: #{@player.health}", 10, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    else
      @game_over_screen.draw
      @font.draw("Score: #{@player.score}", 500, 360, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end
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
    @x = 350
    @y = 550
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

  def game_over
    if @health < 0
      puts "Health: GAME OVER"
      @game_over = true
    end
  end

  def hit_shark(shark)
    if Gosu.distance(@x, @y, shark.x, shark.y) < 50
      @health -= 1
    end
  end

  def visit_doctor(doctor)
    if Gosu.distance(@x, @y, doctor.x, doctor.y) < 50 and @score > 0
      @score -= 1
      @health += 1
    end
  end

  def hit_bomb(bomb)
    if Gosu.distance(@x, @y, bomb.x, bomb.y) < 50
      puts "Bomb: GAME OVER"
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

  def collect_powerups(powerups, seashells)
    powerups.reject! do |powerup|
      if Gosu.distance(@x, @y, powerup.x, powerup.y) < 35
        if powerup.is_a?(HealthPowerup)
          @health += 50
          true
        elsif powerup.is_a?(DoublePointsPowerup)
          @score *= 2
          true
        elsif powerup.is_a?(MagnetPowerup)
          @score += (seashells.size * 10)
          seashells.clear
        end
      elsif powerup.timer > 600
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
    img.draw_rot(@x, @y, ZOrder::UI, 50 * Math.sin(Gosu.milliseconds / 133.7))
    # img.draw(@x - img.width / 2.0, @y - img.height / 2.0, ZOrder::SEASHELLS, 1, 1, @color, :add)
  end
end

class HealthPowerup
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @x = rand * 1200
    @y = rand * 700
    @timer = 0
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw_rot(@x, @y, ZOrder::UI, 50 * Math.sin(Gosu.milliseconds / 133.7))
  end

  def timer
    @timer
  end

  def update
    @timer += 1
  end
end

class DoublePointsPowerup
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @x = rand * 1200
    @y = rand * 700
    @timer = 0
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw_rot(@x, @y, ZOrder::UI, 50 * Math.sin(Gosu.milliseconds / 133.7))
  end

  def timer
    @timer
  end

  def update
    @timer += 1
  end
end

class MagnetPowerup
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @x = rand * 1200
    @y = rand * 700
    @timer = 0
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw_rot(@x, @y, ZOrder::UI, 50 * Math.sin(Gosu.milliseconds / 133.7))
  end

  def timer
    @timer
  end

  def update
    @timer += 1
  end
end

class GameOverScreen
  def initialize
    @background_image = Gosu::Image.new("underwater2.png", :tileable => true)
    @font = Gosu::Font.new(50)
  end

  def draw
    @background_image.draw(0, 0, ZOrder::UI)
    @font.draw("GAME OVER", 500, 300, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end
end

class GameScreen
  def initialize
    @background_image = Gosu::Image.new("underwater2.png", :tileable => true)
  end

  def draw
    # upper left corner drawn at (0,0) with z ordering of 0
    # higher z = drawn on top of lower z
    @background_image.draw(0, 0, ZOrder::BACKGROUND)
  end
end

# create a window and call its show method
# main loop
Tutorial.new.show


















