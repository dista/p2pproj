package  
{
	import flash.events.Event;
    import flash.utils.ByteArray;
	
	/**
     * ...
     * @author dista
     */
    public class PieceContentEvent extends Event 
    {
        public var error:int;
        public var remoteID:String;
        public var id:int;
        public var content:ByteArray;
        
        public function PieceContentEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}