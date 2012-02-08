module PT

  class CursesInterface
    def initialize(screen)
      @screen = screen
      @story_row = 1
      @menu_window = Ncurses.newwin(20,30,0,0)
      @preview_window = Ncurses.newwin(50,100,0,35)
      @menu_options = {
        "My work" => 109,
        "Current Sprint" => 99,
        "Next Sprint" => 110
      }
    end

    def show_menu
      @menu_window.mvaddstr(1,1,"Menu:")
      @menu_window.mvaddstr(2,1,"-----")
      menu_row = 3
      @menu_options.each do |option, character|
        @menu_window.mvaddstr(menu_row,1,"#{character.chr}: #{option}")
        menu_row+=1
      end
      @menu_window.box(0,0)
      @menu_window.refresh()
    end

    def show_story_list(stories)
      row = @story_row
      @preview_window.clear()
      stories.each do |story|
        @preview_window.mvaddstr(row, 1, "#{row}. #{story.name}")
        row+=1
      end
      @preview_window.box(0,0)
      @preview_window.refresh()
      @story_row = row
      @preview_window.getch()
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
