package  
{
    import flash.external.ExternalInterface;
    
	/**
     * ...
     * @author dista
     */
    public class Logger 
    {
        
        public function Logger() 
        {
            
        }
        
        public static function log(msg:Object):void {
            if (ExternalInterface.available)
            {
                ExternalInterface.call("log", msg.toString());
            }
            else {
                trace(msg);
            }
        }
    }

}