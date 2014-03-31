package  
{
    import com.adobe.net.URI;
    import com.adobe.protocols.dict.events.ErrorEvent;
    import flash.utils.ByteArray;
    import org.httpclient.events.HttpStatusEvent;
    import org.httpclient.events.HttpDataEvent;
    import org.httpclient.events.HttpResponseEvent;
    import org.httpclient.http.Get;
    import org.httpclient.HttpClient;
    import org.httpclient.HttpRequest;
	/**
     * ...
     * @author dista
     */
    public class HttpTracker extends ITracker 
    {
        
        public function HttpTracker() 
        {
            
        }
        
        private function parsePlayList(playlist:String):Object {
            var ret:Object = new Object();
            var tmp:Array = playlist.split('\n');
            ret["samples"] = [];
            
            for (var i:String in tmp) {
                var l:String = tmp[i];
                var x:String = l.charAt(0);
                if (x == "h" || x == "m" || x == "v" || x == "a") {
                    var xx:Array = l.split(" ");
                    var p:Array = xx[1].split("-");
                    ret[xx[0]] = [parseInt(p[0], 10), parseInt(p[1], 10)]
                }
                else if (x == "p")
                {
                     var p:Array = l.split(" ");
                     var m:Array = p[1].split("-");
                     var w:Array = [];
                     w.push(parseInt(m[0], 10));
                     w.push(parseInt(m[1], 10));
                     w.push(parseInt(p[2].slice(1), 10));
                     w.push(parseInt(p[3].slice(1), 10));
                     w.push(parseInt(p[4].slice(2), 10));
                     ret["samples"].push(w);
                }
            }
            
            return ret;
        }
        
        public override function getPiece(fileName:String, start:Number, len:Number):void
        {
            //Logger.log("GET PIECE");
            var client:HttpClient = new HttpClient();
            var piece_data:ByteArray = new ByteArray();
            
            client.listener.onStatus = function(event:HttpStatusEvent):void {
            }
            
            client.listener.onData = function(event:HttpDataEvent):void {
                piece_data.writeBytes(event.bytes);
                //trace(piece_data.length);
            }
            
            client.listener.onComplete = function(event:HttpResponseEvent):void {
                var e:PieceEvent = new PieceEvent("ON_GET_PIECE");
                e.data = piece_data;
                //trace("len: " + piece_data.length);
                dispatchEvent(e);
            }
            
            var request:HttpRequest = new Get();
            request.addHeader("Range", "bytes=" + start + "-" + (start + len - 1));
            
            var uri:URI = new URI("http://192.168.1.104:8081/x.flv");
            client.request(uri, request);
        }
        
        public override function getPlaylist(fileName:String):void {
            //Logger.log("GET PLAYLIST");
            var client:HttpClient = new HttpClient();
            var playlist:String = "";
            
            client.listener.onStatus = function(event:HttpStatusEvent):void {
            }
            
            client.listener.onData = function(event:HttpDataEvent):void {
                //trace(event.readUTFBytes());
                playlist = playlist + event.readUTFBytes();
                //var playlist:String = event.readUTFBytes();
                //trace(playlist);

            }
            
            client.listener.onComplete = function(event:HttpResponseEvent):void {
                var playlistMeta:Object = parsePlayList(playlist);
            
                var e:PlayListEvent = new PlayListEvent("ON_GET_PLAYLIST");
                e.playlist = playlistMeta;
                //Logger.log("GET PLAYLIST DONE");
                dispatchEvent(e);
            }
            
            var request:HttpRequest = new Get();
            //request.addHeader("Range", "bytes=0-10");
            
            var uri:URI = new URI("http://192.168.1.104:8081/pp");
            client.request(uri, request);
        }
    }

}