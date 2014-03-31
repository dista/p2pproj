package  
{
    import flash.events.EventDispatcher;
	/**
     * ...
     * @author dista
     */
    public class ITracker extends EventDispatcher
    {
        public function getPeers():void { };
        public function getPlaylist(fileName:String):void { }
        public function getPiece(fileName:String, start:Number, len:Number):void {}
    }

}