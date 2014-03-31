package  
{
	import flash.events.Event;
    import flash.utils.ByteArray;
	
	/**
     * ...
     * @author dista
     */
    public class PieceEvent extends Event 
    {
        public var data:ByteArray;
        public function PieceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
        {
            super(type, bubbles, cancelable);
			
        }
        
    }

}