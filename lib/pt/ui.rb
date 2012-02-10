require 'yaml'
require 'colored'
require 'highline'

class PT::UI

  def initialize(args)
    require 'pt/debugger' if ARGV.delete('--debug')
    @io = HighLine.new
    @global_config = PT.load_global_config
    @local_config = PT.load_local_config
    @project = PT.project
    @client = PT.client
    command = args[0].to_sym rescue :my_work
    @params = args[1..-1]
    commands.include?(command.to_sym) ? send(command.to_sym) : help
  end

  def my_work
    stories = @client.get_my_work(@project, @local_config[:user_name])

    title("My Work for #{user_s} in #{project_to_s}")
    PT::TasksTable.new(stories).print
  end

  def list
    if @params[0] 
      user = find_owner @params[0]
      if user
        stories = @client.get_my_work(@project, user.name)
        PT::TasksTable.new(stories).print
      end
    else
      members = @client.get_members(@project)
      table = PT::MembersTable.new(members)
      user = select("Please select a member to see his tasks", table).name
      title("Work for #{user} in #{project_to_s}")
      stories = @client.get_my_work(@project, user)
      PT::TasksTable.new(stories).print
    end
  end

  def create
    if @params[0]
      name = @params[0]
      owner = find_owner @params[1]
      requester = @local_config[:user_name]
      task_type = @params[2] || 'feature'
    else
      title("Let's create a new task:")
      name = ask("Name for the new task:")
    end
    
    unless owner
      if ask('Do you want to assign it now? (y/n)').downcase == 'y'
        members = @client.get_members(@project)
        table = PT::MembersTable.new(members)
        owner = select("Please select a member to assign him the task", table).name
      else
        owner = nil
      end
      requester = @local_config[:user_name]
      task_type = ask('Type? (c)hore, (b)ug, anything else for feature)')
    end
    
    task_type = case task_type
    when 'c', 'chore'
      'chore'
    when 'b', 'bug'
      'bug'
    else
      'feature'
    end
    result = @client.create_task(@project, name, owner.name, requester, task_type)
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task created, yay!")
    end
  end

  def open
    if @params[0] 
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[ @params[0].to_i ]
      congrats("Opening #{task.name}")
    else
      tasks = @client.get_my_open_tasks(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to open it in the browser", table)
    end
    `open #{task.url}`
  end

  def comment
    tasks = @client.get_my_work(@project, @local_config[:user_name])
    table = PT::TasksTable.new(tasks)
    if @params[0]
      task = table[ @params[0].to_i ]
      comment = @params[1]
      title("Adding a comment to #{task.name}")
    else
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to comment it", table)
      comment = ask("Write your comment")      
    end
    if @client.comment_task(@project, task, comment)
      congrats("Comment sent, thanks!")
    else
      error("Ummm, something went wrong.")
    end
  end

  def assign
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      owner = find_owner @params[1]
    else    
      title("Tasks for #{user_s} in #{project_to_s}")
      tasks = @client.get_tasks_to_assign(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = select("Please select a task to assign it an owner", table)
      members = @client.get_members(@project)
      table = PT::MembersTable.new(members)
      owner = select("Please select a member to assign him the task", table).name
    end
    result = @client.assign_task(@project, task, owner.name)
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task assigned to #{owner}, thanks!")
    end
  end

  def estimate
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Estimating '#{task.name}'")  
      
      if [0,1,2,3].include? @params[1].to_i
        estimation = @params[1]
      end
    else
      tasks = @client.get_my_tasks_to_estimate(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to estimate it", table)
    end
    
    estimation ||= ask("How many points you estimate for it? (#{@project.point_scale})")    
    result = @client.estimate_task(@project, task, estimation)
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task estimated, thanks!")
    end
  end

  def start    
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Starting '#{task.name}'")
    else
      tasks = @client.get_my_tasks_to_start(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to mark it as started", table)    
    end
    start_task task
  end

  def finish
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Finishing '#{task.name}'")
    else
      tasks = @client.get_my_tasks_to_finish(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to mark it as finished", table)    
    end
    finish_task task
  end

  def deliver
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Delivering '#{task.name}'")
    else
      tasks = @client.get_my_tasks_to_deliver(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to mark it as delivered", table)    
    end

    deliver_task task
  end

  def accept
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Accepting '#{task.name}'")
    else
      tasks = @client.get_my_tasks_to_accept(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to mark it as accepted", table)    
    end
    result = @client.mark_task_as(@project, task, 'accepted')
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task accepted, hooray!")
    end
  end

  def show
    title("Tasks for #{user_s} in #{project_to_s}")
    tasks = @client.get_my_work(@project, @local_config[:user_name])
    table = PT::TasksTable.new(tasks)
    if @params[0]
      task = table[@params[0].to_i]
    else
      task = select("Please select a story to show", table)
    end
    
    result = show_task(task)
  end

  def reject
    title("Tasks for #{user_s} in #{project_to_s}")
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]
      title("Rejecting '#{task.name}'")
    else
      tasks = @client.get_my_tasks_to_reject(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      title("Tasks for #{user_s} in #{project_to_s}")
      task = select("Please select a story to mark it as rejected", table)    
    end

    if @params[1]
      comment = @params[1]
    else
      comment = ask("Please explain why are you rejecting the task")
    end
    
    if @client.comment_task(@project, task, comment)
      result = @client.mark_task_as(@project, task, 'rejected')
      congrats("Task rejected, thanks!")
    else
      error("Ummm, something went wrong.")
    end
  end

  def done 
    if @params[0]
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      table = PT::TasksTable.new(tasks)
      task = table[@params[0].to_i]

      #we need this for finding again later
      task_id = task.id

      if !@params[1] && task.estimate == -1
        error("You need to give an estimate for this task")
        return
      end

      if @params[1] && task.estimate == -1
          if [0,1,2,3].include? @params[1].to_i
            estimate_task(task, @params[1].to_i)
          end
      end

      task = find_my_task_by_task_id task_id
      start_task task

      task = find_my_task_by_task_id task_id
      finish_task task
      
      task = find_my_task_by_task_id task_id
      deliver_task task
    end
  end

  def estimate_task task, difficulty
    result = @client.estimate_task(@project, task, difficulty)
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task estimated, thanks!")
    end
  end

  def start_task task
    result = @client.mark_task_as(@project, task, 'started')
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task started, go for it!")
    end
  end

  def finish_task task
    if task.story_type == 'chore'
      result = @client.mark_task_as(@project, task, 'accepted')
    else
      result = @client.mark_task_as(@project, task, 'finished')
    end
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Another task bites the dust, yeah!")
    end
  end

  def deliver_task task
    return if task.story_type == 'chore'

    result = @client.mark_task_as(@project, task, 'delivered')
    error(result.errors.errors) if result.errors.any?
    if result.errors.any?
      error(result.errors.errors)
    else
      congrats("Task delivered, congrats!")
    end
  end

  def find
    tasks = @client.get_my_work(@project, @local_config[:user_name])
    if @params[0]
      tasks.each do | task |
        if (task.name.downcase.index @params[0]) && (task.current_state != 'delivered')
          title("--- [#{(tasks.index task) + 1 }] -----------------")
          show_task(task)
        end
      end
    else
      message("You need to provide a substring for a tasks title.")
    end
  end
  
  def updates
    activities = @client.get_activities(@project)
    tasks = @client.get_my_work(@project, @local_config[:user_name])
    title("Recent Activity on #{project_to_s}")
    activities.each do |activity|
      show_activity(activity, tasks)
    end
  end

  
  def help 
    if ARGV[0]
      message("Command #{ARGV[0]} not recognized. Showing help.")
    end
    
    title("Command line usage")
    message("pt                                     # show all available tasks")
    message("pt create    [title] ~[owner] ~[type]  # create a new task")
    message("pt show      [id]                      # shows detailed info about a task")
    message("pt open      [id]                      # open a task in the browser")
    message("pt assign    [id] [member]             # assign owner")
    message("pt comment   [id] [comment]            # add a comment")
    message("pt estimate  [id] [0-3]                # estimate a task in points scale")
    message("pt start     [id]                      # mark a task as started")
    message("pt finish    [id]                      # indicate you've finished a task")
    message("pt deliver   [id]                      # indicate the task is delivered");
    message("pt accept    [id]                      # mark a task as accepted")
    message("pt reject    [id] [reason]             # mark a task as rejected, explaining why")
    message("pt find      [query]                   # looks in your tasks by title and presents it")
    message("pt done      [id] ~[0-3]               # lazy mans finish task, does everything")
    message("pt list      [member]                  # list all tasks for another pt user")
    message("pt updates                             # show recent activity from your current project")
    message("")
    message("All commands can be ran without arguments for a wizard like UI.")
  end

  protected

  def commands
    (public_methods - Object.public_methods).sort.map{ |c| c.to_sym}
  end

  # I/O
  def split_lines(text)
    text.respond_to?(:join) ? text.join("\n") : text
  end

  def title(*msg)
    puts "\n#{split_lines(msg)}".bold
  end

  def congrats(*msg)
    puts "\n#{split_lines(msg).green.bold}"
  end

  def message(*msg)
    puts "\n#{split_lines(msg)}"
  end

  def error(*msg)
    puts "\n#{split_lines(msg).red.bold}"
  end

  def select(msg, table)
    if table.length > 0
      begin
        table.print
        row = ask "#{msg} (1-#{table.length}, 'q' to exit)"
        quit if row == 'q'
        selected = table[row]
        error "Invalid selection, try again:" unless selected
      end until selected
      selected
    else
      table.print
      message "Sorry, there are no options to select."
      quit
    end
  end

  def quit
    message "bye!"
    exit
  end

  def ask(msg)
    @io.ask("#{msg.bold}")
  end

  def ask_secret(msg)
    @io.ask("#{msg.bold}"){ |q| q.echo = '*' }
  end

  def user_s
    "#{@local_config[:user_name]} (#{@local_config[:user_initials]})"
  end

  def project_to_s
    "Project #{@local_config[:project_name].upcase}"
  end
  
  def find_task query    
    members = @client.get_members(@project)
    members.each do | member |
      if member.name.downcase.index query
        return member.name
      end
    end
    nil
  end
  
  def find_my_task_by_task_id task_id    
      tasks = @client.get_my_work(@project, @local_config[:user_name])
      tasks.each do |task|
        if task.id == task_id
          return task
        end
      end
  end

  def find_owner query    
    members = @client.get_members(@project)
    members.each do | member |
      if member.name.downcase.index query
        return member
      end
    end
    nil
  end
    
  def show_task(task)
    title task.name
    estimation = [-1, nil].include?(task.estimate) ? "Unestimated" : "#{task.estimate} points"
    message "#{task.current_state.capitalize} #{task.story_type} | #{estimation} | Req: #{task.requested_by} | Owns: #{task.owned_by} | Id: #{task.id}"
    message task.description unless task.description.empty?
    task.tasks.all.each{ |t| message "- #{t.complete ? "(done) " : "(pend)"} #{t.description}" }
    task.notes.all.each{ |n| message "#{n.author}: \"#{n.text}\"" }
    task.attachments.each{ |a| message "#{a.uploaded_by} uploaded: \"#{a.description.empty? ? "#{a.filename}" : "#{a.description} (#{a.filename})" }\" #{a.url}" }
  end
  
  def show_activity(activity, tasks)
    story_id = activity.stories.first.id
    task_id = nil
    tasks.each do |story|
      if story_id == story.id
        task_id = tasks.index(story)
      end
    end
    message("#{activity.description} [#{task_id}]")
  end
  
end
