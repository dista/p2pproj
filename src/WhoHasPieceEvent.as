package  
{
	import flash.events.Event;
	
	/**
     * ...
     * @author dista
     */
    public class WhoHasPieceEvent extends Event 
    {
        public var remoteID:String;
        public var pieceID:int;
        
        public function WhoHasPieceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}