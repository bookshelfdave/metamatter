require "wx"

class MMWin < Wx::Frame
  def initialize
    super(nil, -1, "Metamatter")  
  end  
end

class MMGui < Wx::App  
  def on_init  
    m = MMWin.new()
    Wx::StaticText.new(m,-1,"Wow, I have alot of coding to do",Wx::Point.new(10,10),Wx::Size.new(50,50))  
    m.show()  
  end
end

mmgui = MMGui.new
mmgui.main_loop
