module PT

  class CursesInterface
    def initialize(screen)
      @screen = screen
      @story_row = 1
    end

    def print_title(title)
      @screen.mvaddstr(0,0,title)
    end

    def show_story_list(stories)
      row = @story_row
      stories.each do |story|
        @screen.mvaddstr(row, 0, "#{row}. #{story.name}")
        row+=1
      end
      @story_row = row
    end

    def select_story
      @screen.mvaddstr(@story_row,0,"Which story would you like to see?:")
      Ncurses.raw()
      Ncurses.noecho()
      @story_row+=1
      char = Ncurses.mvgetch(@story_row,0)
      @screen.mvaddstr(@story_row,0,"#{char}") # showing 50 for 2 - char code?
    end
  end

end
