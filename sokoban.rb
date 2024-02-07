require 'gosu'

$example_level = [
"    #####          ",
"    #   #          ",
"    #o  #          ",
"  ###  o##         ",
"  #  o o #         ",
"### # ## #   ######",
"#   # ## #####  ..#",
"# o  o          ..#",
"##### ### #@##  ..#",
"    #     #########",
"    #######        "
]

module TextSprite
  def sprite(name, char, color)
    define_method "draw_#{name}" do |x, y|
      @draw.call(char, x, y)
    end

    define_method name do
      char
    end
  end
end

extend TextSprite

sprite :player, "@", "blue"
sprite :wall, "#", "gray"
sprite :crate, 'o', "green"
sprite :goal, '.', "yellow"
sprite :empty, ' ', "black"

class Map
  def initialize(level)
    @level = level
    @grid = []
    @goals = []
    @player_pos = nil
  end

  def load
    @level.each_with_index do |row, y|
      row.chars.each_with_index do |cell, x|
        @grid[y] ||= []
        @grid[y][x] = cell
        if cell == player
          @player_pos = [x, y]
          @grid[y][x] = empty
        elsif cell == goal
          @goals << [x, y]
        end 
      end
    end
    [@player_pos, @grid, @goals]
  end
end

class Sokoban
  def initialize(draw_method, level=$example_level)
    @draw = draw_method
    @complete = false
    @player_pos, @grid, @goals = Map.new(level).load
  end
  
  def draw_level
    @goals.each { |x, y| draw_goal(x, y) }
    
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        case cell
        when wall
          draw_wall(x, y)
        when crate
          draw_crate(x, y)
        when goal
          draw_goal(x, y)
        end
      end
    end

    draw_player(*@player_pos)
    @draw.call("Level complete!", 1, 28) if @complete
  end

  def move(direction)
    dx, dy = getdir(direction)

    new_x, new_y = @player_pos[0] + dx, @player_pos[1] + dy
    target_cell = @grid[new_y][new_x]

    case target_cell
    when empty, goal
      move_player(new_x, new_y)
    when crate
      new_crate_x, new_crate_y = new_x + dx, new_y + dy
      move_crate(new_crate_x, new_crate_y, new_x, new_y)
    end

    @complete = true if complete?
  end

  private

  def move_player(x, y)
    @grid[@player_pos[1]][@player_pos[0]] = empty
    @player_pos = [x, y]
  end

  def move_crate(new_crate_x, new_crate_y, new_x, new_y)
    if @grid[new_crate_y][new_crate_x] == empty || @grid[new_crate_y][new_crate_x] == goal
      @grid[new_crate_y][new_crate_x] = crate
      @grid[new_y][new_x] = empty
      move_player(new_x, new_y)
    end
  end

  def complete?
    @goals.each do |x, y|
      return false if @grid[y][x] != crate
    end
    true
  end

  def getdir(direction)
    case direction
    when :left
      dx, dy = -1, 0
    when :right
      dx, dy = 1, 0
    when :up
      dx, dy = 0, -1
    when :down
      dx, dy = 0, 1
    end
    [dx, dy]
  end
end

class Game < Gosu::Window
  def initialize
    super 640, 480
    self.caption = "Tutorial Game"
    @char_size = 16
    @font = Gosu::Font.new(20, name: "Consolas")
    @sokoban = Sokoban.new(draw_method = method(:draw_char))
  end

  def button_down(button_id)
    case button_id
    when Gosu::KB_LEFT
      @sokoban.move :left
    when Gosu::KB_RIGHT
      @sokoban.move :right
    when Gosu::KB_UP
      @sokoban.move :up
    when Gosu::KB_DOWN
      @sokoban.move :down
    when Gosu::KB_ESCAPE
      close
    else
      super
    end
  end

  def update
  end

  def draw
    @sokoban.draw_level
  end

  def draw_char(char, x, y)
    @font.draw_text(char, x * @char_size, y * @char_size, 0, 1.0, 1.0, Gosu::Color::WHITE)
  end
end

Game.new.show