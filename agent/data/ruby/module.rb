# Sample Override for hours till next service to throw error

class AlertTransform < MTConnect::RubyTransform
  def initialize(name, filter)
    @cache = Hash.new
    super(name, filter)
  end

  @@count = 0
  def transform(obs)
    @@count += 1
    if @@count % 10000 == 0
      puts "---------------------------"
      puts ">  #{ObjectSpace.count_objects}"
      puts "---------------------------"
    end
    
    dataItemId = obs.properties[:dataItemId]
    if dataItemId == 'saw_time_till_next_service' or dataItemId == 'saw_operating'
      @cache[dataItemId] = obs.value
      device = MTConnect.agent.default_device
      
      di = device.data_item('saw_hydraulic_low_level')
      if @cache['saw_time_till_next_service'].to_f <= 0.0 and @cache['Xfrt'].to_f == "ON"
        newobs = MTConnect::Observation.new(di, "ERROR")
      end
      forward(newobs)
    end
    forward(obs)
  end
end
      
MTConnect.agent.sources.each do |s|
  pipe = s.pipeline
  puts "Splicing the pipeline"
  trans = AlertTransform.new('AlertTransform', :Sample)
  puts trans
  pipe.splice_before('DeliverObservation', trans)
end