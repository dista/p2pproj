package  
{
	import flash.events.Event;
	
	/**
     * ...
     * @author dista
     */
    public class NeedPieceEvent extends Event 
    {
        public var remoteID:String;
        public var pieceID:int;
        
        public function NeedPieceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}