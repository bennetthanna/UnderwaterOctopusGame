require 'gosu'

# https://leanpub.com/developing-games-with-ruby/read

class Tutorial < Gosu::Window
	def initialize
    # create a 640 x 480 pixel large window
    super 1280, 720
    # title bar
    self.caption = "Game"
    @background_image = Gosu::Image.new("underwater2.png", :tileable => true)
    @player = Player.new
    @shark = Shark.new
    @player.warp(640, 360)
    @seashell_anim = Gosu::Image.load_tiles("seashell.png", 40, 38)
    @seashells = Array.new
    @font = Gosu::Font.new(20)
    @counter = 0
  end

  # called 60 times per second
  # contain main game logic
    # ex: moving objects, testing for collisions
  def update
    @counter = @counter + 1
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
    @player.hit_shark(@shark)

    if rand(100) < 4 and @seashells.size < 50
      @seashells.push(Seashell.new(@seashell_anim))
    end

    @shark.move_left

  end

  # called 60 times per second
  # should contain code to redraw the scene
  # no game logic
  def draw
    @player.draw
    @shark.draw
    # upper left corner drawn at (0,0) with z ordering of 0
    # higher z = drawn on top of lower z
    @background_image.draw(0, 0, ZOrder::BACKGROUND)
    @seashells.each { |seashell| seashell.draw }
    @font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @font.draw("Health: #{@player.health}", 10, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    if (@shark.x == @player.x and @shark.y == @player.y)
      @font.draw("OH NO", 300, 300, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
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
    @image.draw(@x, @y, ZOrder::PLAYER)
  end

  def update
    @image.draw(@x, @y, ZOrder::PLAYER)
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
    if Gosu.distance(@x, @y, shark.x, shark.y) < 35
      @health -= 1
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
# create a window and call its show method
# main loop
Tutorial.new.show


















