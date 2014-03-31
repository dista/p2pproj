package  
{
	import flash.events.Event;
	
	/**
     * ...
     * @author dista
     */
    public class PlayListEvent extends Event 
    {
        public var playlist:Object;
        
        public function PlayListEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}