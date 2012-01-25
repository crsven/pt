module PT
  
  class CursesInterface
    def initialize(screen)
      @screen = screen
    end

    def show_story_list(stories)
      row = 1
      stories.each do |story|
        @screen.mvaddstr(row, 0, "#{row}. #{story.name}")
        row+=1
      end
    end

    def select_story
      @screen.mvaddstr(row,0,"Which story would you like to see?:")
      Ncurses.raw()
      Ncurses.noecho()
      @screen.mvgetch(row+1,0)
    end
  end

end
