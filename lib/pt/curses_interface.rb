module PT

  class CursesInterface
    def initialize(screen)
      @screen = screen
      @story_row = 1
      @menu_window = Ncurses.newwin(20,30,0,0)
      @preview_window = Ncurses.newwin(50,100,0,35)
      @menu_options = {
        109 => "My work",
        99 => "Current Sprint",
        110 => "Next Sprint",
        81 => "Quit"
      }
      @preview_options = Hash.new
    end

    def get_input(window)
      global_options = @menu_options.merge(@preview_options)
      selection = window.getch()
      # global_options contains a hash of character codes and functions (currently strings to test)
      if global_options.has_key?(selection)
        window.mvaddstr(10,1,"#{global_options[selection]}")
      end
    end

    def show_menu
      @menu_window.mvaddstr(1,1,"Menu:")
      @menu_window.mvaddstr(2,1,"-----")
      menu_row = 3
      @menu_options.each do |character, option|
        @menu_window.mvaddstr(menu_row,1,"#{character.chr}: #{option}")
        menu_row+=1
      end
      @menu_window.box(0,0)
      @menu_window.refresh()
    end

    def show_story_list(stories)
      @stories = stories
      row = @story_row
      @preview_window.clear()
      stories.each do |story|
        @preview_window.mvaddstr(row, 1, "#{row}. #{story.name}")
        @preview_options["#{row}"[0]] = story.id
        row+=1
      end
      @preview_window.box(0,0)
      @preview_window.refresh()
      @story_row = row
      get_input(@preview_window)
      @preview_window.getch()
    end

    def select_story
      @preview_window.mvaddstr(@story_row,1,"Which story would you like to see?:")
      Ncurses.raw()
      Ncurses.noecho()
      @story_row+=1
      char = @preview_window.mvgetch(@story_row,1)
      @preview_window.mvaddstr(@story_row,1,"#{char.chr.to_i}: #{@stories[char.chr.to_i].name}")
    end
  end

end
