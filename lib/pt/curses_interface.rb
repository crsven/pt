module PT

  class CursesInterface
    def initialize(screen)
      @screen = screen
      @story_row = 1
      @menu_window = Ncurses.newwin(20,20,0,0)
      @menu_window.box(0,0)
      @menu_window.refresh()
      @preview_window = Ncurses.newwin(50,100,0,21)
      @preview_window.box(0,0)
      @preview_window.refresh()
    end

    def show_menu
      @menu_window.mvaddstr(1,1,"Menu:")
      @menu_window.mvaddstr(2,1,"-----")
      @menu_window.refresh()
    end

    def print_title(window, title)
      window.wprintw(title)
    end

    def show_story_list(stories)
      row = @story_row
      stories.each do |story|
        @preview_window.mvaddstr(row, 1, "#{row}. #{story.name}")
        row+=1
      end
      @preview_window.refresh()
      @menu_window.getch()
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
