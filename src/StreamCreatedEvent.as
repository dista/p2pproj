package  
{
	import flash.events.Event;
    import flash.net.NetStream;
	
	/**
     * ...
     * @author dista
     */
    public class StreamCreatedEvent extends Event 
    {
        public var stream:NetStream;
        public function StreamCreatedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}