package  
{
	import flash.events.Event;
	
	/**
     * ...
     * @author dista
     */
    public class GetPeersEvent extends Event 
    {
        public var peers:Array;
        public function GetPeersEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}