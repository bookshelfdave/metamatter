require "wx"
require "mm/mm.rb"

class MMWin < Wx::Frame
  
  def initialize    
    super(nil, -1, "Metamatter",Wx::DEFAULT_POSITION,Wx::Size.new(800,600))      
    
    @loadedops = MM::Op.getopnames
    setup_menu

    @draggingop = nil
    @dragoffx = 0
    @dragoffy = 0
    
    #TODO: This will eventually be an array of Ops, not just rects
    @oprects = Array.new()
    
    evt_paint { |event| on_paint(event) }
    evt_left_down { |event| on_left_down(event) }
    evt_left_up { |event| on_left_up(event) }
    evt_motion { |event| on_mouse_motion(event) }
    evt_right_up { |event| on_right_up(event) }
    
  end  

  def on_mouse_motion(event)
    if not @draggingop.nil?
      # TODO: top right and bottom left corner are missing a pixel when dragged up-right or down-left
      # hmm.. not exactly sure why i need to add 2 to each of these. im assuming it's the width of
      # the border, but...why? shouldn't the border be included inside the rect?
      @oldrect = Wx::Rect.new(@draggingop.x, @draggingop.y, 
                              @draggingop.width+2, @draggingop.height+2)
      # and why do i need to subtract 1 from here?
      @draggingop.x = event.get_x - @dragoffx -2 
      @draggingop.y = event.get_y - @dragoffy -2
      biggerrect = Wx::Rect.new(@draggingop.x, @draggingop.y, 
                                 @draggingop.width+2, @draggingop.height+2)
      refresh_rect(@oldrect,true)
      refresh_rect(@draggingop,true)
      refresh_rect(biggerrect,true)
    end
  end
  
  def on_right_up(event)
    clickedop = @oprects.find { |rect| rect.contains(event.get_x, event.get_y) }
    if clickedop.nil?
      @popup_location=event.get_position
      popup_menu(@opmenu)
    else
      puts "No op selected"
    end    
  end
  
  def on_left_down(event)
    #puts "Left down: #{event.get_x} #{event.get_y}"
    clickedop = @oprects.find { |rect| rect.contains(event.get_x, event.get_y) }
    if not clickedop.nil?
      @draggingop = clickedop 
      @dragoffx = event.get_x - @draggingop.x
      @dragoffy = event.get_y - @draggingop.y
    end
  end
  
  def on_left_up(event)
    @draggingop = nil
    @oldrect = nil
  end
  
  def on_paint(event)
    rect = self.get_client_size    
    paint do |dc|
      gdc = Wx::GraphicsContext.create(dc)      
      
      @oprects.each do |r|
        gdc.set_pen(Wx::BLACK_PEN)
        gdc.set_brush(Wx::MEDIUM_GREY_BRUSH)  
        gdc.draw_rounded_rectangle(r.x,r.y,r.width,r.height,10)
      end
      
      
    end
  end

  def setup_menu
    @opmenu = Wx::Menu.new("Opmenu")
    @loadedops.each_with_index do |op,index|     
      item = @opmenu.append(index,op.name[4..-1])
      evt_menu(index) {|event| op_menu_selection(event,index) }
    end
  end

  def op_menu_selection(event,index)
    puts "Creating #{@loadedops[index]} @ #{@popup_location}"    
    rect = Wx::Rect.new(@popup_location.x,@popup_location.y,75,40)
    @oprects << rect
    biggerrect = Wx::Rect.new(rect.x, rect.y, 
                                 rect.width+2, rect.height+2)
    refresh_rect(biggerrect,true)
  end
end

class MMGui < Wx::App  
  def on_init  
    m = MMWin.new()
    m.show()  
  end
end

mmgui = MMGui.new
mmgui.main_loop
