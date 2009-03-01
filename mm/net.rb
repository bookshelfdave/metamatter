require 'mm.rb'

n = Network.new do
 
  p = create :Print
  e = create :Echo
  i = create :If
  m = create :Mod
  t = create :TextTemplate
 
  p.prefix = "ECHO1:"
  m.code = "value.upcase!"
 
  e.echoout >> i.ifin
  i.ifouttrue >> m.modin
  m.modout >> p.printin
 
  e.echo "This is a test"
end

#n.start