package  
{
	import flash.events.Event;
	
	/**
     * ...
     * @author dista
     */
    public class NoOneHasPieceEvent extends Event 
    {
        
        public function NoOneHasPieceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}