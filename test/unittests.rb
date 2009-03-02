#    
#    MetaMatter
#    Copyright (C) 2009 Dave Parfitt
# Create pipe out as
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



require 'test/unit'
require 'mm/mm.rb'
require 'stringio'

class TC_Simple < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_simple
	s = StringIO.new()
	net = MM::Network.new do
  		foo = create :StartupEcho
  		output = create :Print
  		output.fd = s
  		foo.echoout >> output.printin
	end
	net.run
	s.rewind
	assert(s.readline == "Foo\n","Simple test failed :-(")
  end

  def test_gate1
	s = StringIO.new()
	net = MM::Network.new do
  	foo1 = create :StartupEcho
  		foo2 = create :StartupEcho
		gate = create :Gate
		output = create :Print
		join = create :Join

		output.fd = s

		foo1.message = "Foo1"
		foo2.message = "Foo2"

		foo1.echoout >> gate.gatein
		foo2.echoout >> gate.gatein
		gate.gateout >> join.joinin
		join.joinout >> output.printin
	end
	net.run
	s.rewind
	assert(s.readline == "Foo1,Foo2\n")
  end

  def test_gate2
	s = StringIO.new()
	net = MM::Network.new do
  		echo1= create :StartupEcho
  		echo2 = create :StartupEcho
  		echo3= create :StartupEcho

		gate = create :Gate
		output = create :Print
		join = create :Join

		output.fd = s

		echo1.message = "a"
		echo2.message = "b"
		echo3.message = "c"

		echo1.echoin.queue("a")
		echo1.echoin.queue("a")
		echo2.echoin.queue("b")
		echo3.echoin.queue("c")
		echo3.echoin.queue("c")
		echo3.echoin.queue("c")

		echo1.echoin.queue("a")
		echo2.echoin.queue("b")
		echo2.echoin.queue("b")

		echo1.echoout >> gate.gatein
		echo2.echoout >> gate.gatein
		echo3.echoout >> gate.gatein
		gate.gateout >> join.joinin
		join.joinout >> output.printin
	end
	net.run
	s.rewind
	# the stringio should contain three lines
	assert(s.readline == "a,b,c\n")
	assert(s.readline == "a,b,c\n")
	assert(s.readline == "a,b,c\n")
  end
  

  def test_pipeout    
    net = MM::Network.new do
      foo = create :StartupEcho
      output = create :PipeOut, "pipeout1"
      foo.echoout >> output.datain
    end
    net.run    
    assert(net.pipesout[net.getopbytitle("pipeout1").opid].pop == "Foo")
  end
end
