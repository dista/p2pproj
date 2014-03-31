package  
{
    import flash.events.Event;
    import flash.net.NetConnection;
    import flash.net.Responder;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
	/**
     * ...
     * @author dista
     */
    public class CumulusTracker extends ITracker
    {
        private var nc_:NetConnection;
        private var queryPeersRemoteCall:String = "getParticipants";
        private var getPlaylistCall:String = "getPlaylist";
        private var getPieceCall:String = "getPiece";
        
        public function CumulusTracker(nc:NetConnection) 
        {
            nc_ = nc;
        }
        
        /* INTERFACE ITracker */
        
        public override function getPeers():void 
        {
            Logger.log('GET PEERS');
            nc_.call(queryPeersRemoteCall, new Responder(onGetParticipantsResult), "app");
        }
        
        public override function getPlaylist(fileName:String):void {
            Logger.log('GET PLAYLIST');
            nc_.call(getPlaylistCall, new Responder(onGetPlaylist), fileName);
        }
        
        public override function getPiece(fileName:String, start:Number, len:Number):void
        {
            //trace("start: " + start + " len: " + len);
            nc_.call(getPieceCall, new Responder(onGetPiece), fileName, start, len);
        }
        
        private function onGetParticipantsResult(obj:Object):void {
            Logger.log('on GET PEERS');
            var e:GetPeersEvent = new GetPeersEvent("ON_GET_PEERS");
            e.peers = new Array();
            for (var i:int ; i < obj.length; i++) {
                e.peers.push(obj[i].farID);
            }
            dispatchEvent(e);
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
        
        private function onGetPlaylist(obj:Object):void {
            Logger.log("ON GET PLAYLIST");
            var playlist:String = obj as String;
            var playlistMeta:Object = parsePlayList(playlist);
            
            var e:PlayListEvent = new PlayListEvent("ON_GET_PLAYLIST");
            e.playlist = playlistMeta;
            
            dispatchEvent(e);
        }
        
        private function onGetPiece(obj:Object):void {
            /*
            var s:String = obj as String;
            var e:PieceEvent = new PieceEvent("ON_GET_PIECE");
            var p:ByteArray = new ByteArray();
            p.writeUTFBytes(s);
            e.data = p;
            //Logger.log("onGetPiece: " + obj.length);
            trace("len: " + e.data.length);
            */
            //trace("len: " + obj.length + "type: " + typeof(obj));
            var p:ByteArray = new ByteArray();
            for (var i:int = 0; i < obj.length; i++) {
                var xx:String = obj[i] as String;
                p.writeByte(xx.charCodeAt(0));
            }
            var e:PieceEvent = new PieceEvent("ON_GET_PIECE");
            e.data = p;
            //trace("len: " + p.length);
            dispatchEvent(e);
        }
        
    }

}