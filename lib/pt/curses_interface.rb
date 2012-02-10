require 'ncurses'

class PT::CursesInterface
  def initialize
    @global_config = PT.load_global_config
    @local_config = PT.load_local_config
    @project = PT.project
    @client = PT.client
    @screen = Ncurses.initscr()
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
    show_menu
    stories = @client.get_my_work(@project, @local_config[:user_name])
    show_story_list(stories)
    Ncurses.endwin()
  end

  def get_input(output_window)
    global_options = @menu_options.merge(@preview_options)
    Ncurses.raw()
    Ncurses.noecho()
    selection = output_window.getch()
    # global_options contains a hash of character codes and functions (currently strings to test)
    if global_options.has_key?(selection)
      case global_options[selection]
      when "My work"
        print_line(output_window)
      end
    end
  end

  def print_line(window)
    window.mvaddstr(10,1,"Printing a line")
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
    row = @story_row
    @preview_window.clear()
    @preview_options.clear
    stories.each do |story|
      @preview_window.mvaddstr(row, 1, "#{row}. #{story.name}")
      @preview_options["#{row}"[0]] = story.id # TODO: Better way to get character code?
      row+=1
    end
    @preview_window.mvaddstr(row, 1, "Select a story or menu item to continue...")
    @preview_window.box(0,0)
    @preview_window.refresh()
    @story_row = row+1
    get_input(@preview_window)
    @preview_window.getch()
  end
end
