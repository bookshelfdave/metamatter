#
#    MetaMatter 
#    Copyright (C) 2009 Dave Parfitt
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
# 
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
# 
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 

module MM

#need to fixup tabs/whitespace in this file
		
# rules for ops:
# 1) instantiating the Op doesn't cause it to actually do anything
# 2) config + default values cannot be null. They need to return a default
#  value of the correct type
class Network

  def initialize(&block)
    @ops = {}
    instance_eval(&block)    
  end

  def create(opname,title="none")
    op = eval "#{opname}.new"
    op.title = title
    op.network = self
    @ops[op.opid] = op
    op.setupio
    return op
  end

  def run
    @ops.values.each do |op|
      op.starting
    end

    @stophack = 0
    running = true
    while running
      if isdone?
	    #dont know if i need this anymore	
        @stophack = @stophack + 1
      end
      if @stophack == 2
        running = false
      end
      @ops.values.each do |op|
        op.processpacket
      end
    end

	@ops.values.each do |op|
      op.stopping
    end
  end

  def steponceinit
    @ops.values.each do |op|
      op.starting
    end
  end

  def steponce
    @ops.values.each do |op|
        op.processpacket
      end
  end

 
  def isdone?
    livepackets = @ops.values.inject(0) do |result,op|
      result + op.packetcount
    end
    if livepackets == 0
      return true
    else
      return false
    end

  end
end


# a packet keeps track of a value, what input it's going to, and the output where it came from
class Packet
  attr_accessor :destinput
  attr_accessor :value
  attr_accessor :sourceoutput

  def initialize(destinput,value, sourceoutput)   
    @value  = value
    @destinput   = destinput
    @sourceoutput = sourceoutput
  end

  def to_s
    return "Packet #{@sourceoutput}->#{@destinput}[#{@value}]"
  end
 
end

# simple struct to organize an ops internals
class IOs
  attr_accessor :inputs
  attr_accessor :outputs
  attr_accessor :configs

  def initialize
    @inputs  = {}
    @outputs = {}
    @configs = {}
  end
end


# An input to an op instance
class Input
  attr_accessor :owner
  def initialize(owner,name,procname)
    @owner = owner
    @name = name
    @procname = procname
  end

 
  
  def queue(value,source=nil)   
    p = Packet.new(@procname,value,source)
    @owner.packets << p
  end
end

# an output from an op instance
class Output
  def initialize(owner,name)
    @owner = owner
    @name = name
    @connections = []
  end
 
  def >>(input)
    #puts "Connecting to input #{input}"
    @connections << input
    input.owner.connectedto self
  end

  def out(value)   
    @connections.each do |conn|     
      conn.queue(value,self)
    end
  end

  def to_s
    return "#{@owner}.#{@name}"
  end
end


class Op
  # containins definitions of each op type
  @@configs = {}
  @@opidcounter = 0
  attr_accessor :packets
  attr_accessor :title
  attr_accessor :network
  attr_accessor :opid

  def initialize
    ios = @@configs[self.class]

    @opid = @@opidcounter
    @@opidcounter += 1

    #to create an instance of the op, iterate through the list of inputs
    #and outputs and create them dynamically
    ios.inputs.each_pair do |name,pro|
      #puts "Init input #{name}"
      s = "@#{name} = Input.new(self,\"#{name}\",\"#{pro}\")"     
      instance_eval s
    end
    ios.outputs.keys.each do |name|
      s = "@#{name} = Output.new(self,\"#{name}\")"     
      instance_eval s
    end
    @packets = []
  end
  
  # i would like to put these methods somewhere else...
  def Op.listops
    @@configs.keys.join(input ",")
  end

  def Op.getOpInputs(opname)
    @@configs[opname].inputs.keys.join(",")
  end

  def Op.getOpOutputs(opname)
    @@configs[opname].outputs.keys.join(",")
  end

  def Op.getOpConfigs(opname)
    @@configs[opname].configs.keys.join(",")
  end

  def Op.getOpConfigDefaultValueAndType(opname,attname)
    v = instance_eval(opname.to_s + ".new()." + attname.to_s)
    return [v,v.class.name]
  end

  def self.inherited(name)
    #puts "Registered Op->#{name}"
  end
 
  def packetcount
    return @packets.size
  end
 
  # used to define an input in the class definition
  def Op.input(name,proc)   
    attr_reader name

    if not @@configs[self]
      @@configs[self]=IOs.new()
    end
    ios = @@configs[self]
    ios.inputs[name]=proc
  end

  # used to define an output in the class definition
  def Op.output(name)       
    attr_reader name

    if not @@configs[self]
      @@configs[self]=IOs.new()
    end
    ios = @@configs[self]
    ios.outputs[name]=1
  end
  
  # used to define a configurable parameter for an op instance
  def Op.config(name)      
    attr_accessor name
   
    if not @@configs[self]
      @@configs[self]=IOs.new()
    end
    ios = @@configs[self]
    ios.configs[name]=name
  end
    
  # this method processes the next packet in the queue and directs
  # it to the correct method in the op
  def processpacket
    packet = @packets.shift           
    if packet != nil
      self.send(packet.destinput, packet.value)     
      receivedpacket(packet)
    end
  end

  #override me if you like
  def receivedpacket(packet)   
 
  end

  #override me if you like
  def connectedto(output)   
  end

  #override me if you like
  def starting
  end

  #override me if you like
  def stopping
  end

  #override me if you like
  def setupio
  end
end


end # module

require 'mm\ops.rb'





