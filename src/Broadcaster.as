package  
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.events.NetStatusEvent;
    import flash.media.ID3Info;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    
	/**
     * ...
     * @author dista
     */
    public class Broadcaster extends EventDispatcher
    {
        private var nc_:NetConnection;
        private var bc_:NetStream;
        private var peerlists_:Object = new Object();
        private var piece_owners:Object = new Object();
        
        public function Broadcaster(nc:NetConnection) 
        {
            nc_ = nc;
            Logger.log("LOCAL ID: " + nc_.nearID);
        }
        
        public function remotePeer(farID:String):void {
            trace("WE NEED TO REMOVE: " + farID);
        }
        
        public function requestPiece(id:int):void {
            bc_.send("requestPiece", id);
        }
        
        public function indicateIHaveIt(id:int):void {
            bc_.send("havePiece", nc_.nearID, id);
        }
        
        public function requestPiece2(id:int, farID:String):void {
            bc_.send("requestPiece2", id, farID);
        }
        
        public function start(peerlist:Array):void
        {
            bc_ = new NetStream(nc_, NetStream.DIRECT_CONNECTIONS);
            bc_.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
            bc_.publish(nc_.nearID);
            
            var c:Object = new Object();
            c.onPeerConnect = function(subscriber:NetStream):Boolean {
                var farID:String = subscriber.farID;
                
                if (isFarID_Connected(farID)) {
                    return false;
                }
                
                if (!hasConnect_to_Remote(farID)) {
                    connect_to_Remote(farID);
                }
                
                var private_publish:NetStream = new NetStream(nc_, NetStream.DIRECT_CONNECTIONS);
                peerlists_[farID]['private_publish'] = private_publish;
                peerlists_[farID]['private_publish_has_user'] = false;
                private_publish.client = new Object();
                private_publish.client.onPeerConnect = function(sb:NetStream):Boolean {
                    peerlists_[sb.farID]['private_publish_has_user'] = true;
                    trace('private publish has user');
                    return true;
                }
                private_publish.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):void {
                    //trace("publish event: " + event.info.code);
                    //bc_.send("private_publish_established", farID);
                });
                
                var timer:Timer = new Timer(60, 1);
                timer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void {
                    trace("send private_publish_established");
                    bc_.send("private_publish_established", farID);
                });
                timer.start();
                
                Logger.log("private publish, local id " + nc_.nearID + " farId: " + farID);
                private_publish.publish(farID);
                
                return true;
            };
            bc_.client = c;
            
            publicPoint_Connect_Peers(peerlist);
        }
        
        private function publicPoint_Connect_Peers(peerlist:Array):void {
            for (var i:int; i < peerlist.length; i++) {
                var farID:String = peerlist[i];
                
                if (!hasConnect_to_Remote(farID)) {
                    connect_to_Remote(farID);
                }
            }
        }
        
        public function has_established_channel():Boolean {
            for (var k:String in peerlists_) {
                if (peerlists_[k]['private_publish_has_user']
                && peerlists_[k].hasOwnProperty('private_publish_connected_to_remote')
                ) {
                    return true;
                }
            }
            
            return false;
        }
        
        public function who_has_piece(id:int):void {
            var xx:int = 0;
            for (var x:* in peerlists_) {
                xx++;
            }
            trace("who has piece id: " + id +" localID: " + nc_.nearID);
            var idstr:String = "" + id;
            piece_owners[idstr] = new Object();
            piece_owners[idstr]['total_sent'] = 0;
            piece_owners[idstr]['result'] = true;
            for (var k:String in peerlists_) {
                if (peerlists_[k]['private_publish_has_user']
                && peerlists_[k].hasOwnProperty('private_publish_connected_to_remote')
                ) {
                    //trace("send who has piece to: " + k);
                    peerlists_[k]['private_publish'].send("who_has_piece", nc_.nearID, id);
                    piece_owners[idstr]['total_sent']++;
                }
            }
        }
        
        public function i_have_piece(remoteID:String, id:int, has_piece:Boolean):void {
            peerlists_[remoteID]['private_publish'].send('i_have_piece', nc_.nearID, id, has_piece);
        }
        
        public function piece_content(error:int, remoteID:String, id:int, content:ByteArray):void {
            Logger.log("send piece content to: " + remoteID + " pieceid: " + id);
            peerlists_[remoteID]['private_publish'].send('piece_content', error, nc_.nearID, id, content);
        }
        
        private function setFarID_Connected(farID:String):void {
            if (!peerlists_.hasOwnProperty(farID)) {
                peerlists_[farID] = new Object();
            }
            
            peerlists_[farID]["in"] = true;
        }
        
        private function isFarID_Connected(farID:String):Boolean {
            if (!peerlists_.hasOwnProperty(farID)) {
                return false;
            }
            
            return peerlists_[farID]['in'];
        }
        
        private function hasConnect_to_Remote(farID:String):Boolean {
            if (!peerlists_.hasOwnProperty(farID)) {
                return false;
            }
            
            if (peerlists_[farID]['out']) {
                return true;
            }
            
            return false;
        }
        
        private function connect_to_Remote(farID:String):void {
            var ns:NetStream = new NetStream(nc_, farID);
            ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusX);
            ns.client = new Object();
            ns.client.private_publish_established = function(id:String):void {
                if(id == nc_.nearID){
                    trace("private_publish_established callback");
                    connect_to_Remote2(farID, id);
                    peerlists_[farID]['private_publish_connected_to_remote'] = true;
                }
            }
            ns.play(farID);
            //ns.play("ccc");
            
            if (!peerlists_.hasOwnProperty(farID)) {
                peerlists_[farID] = new Object();
            }
            
            peerlists_[farID]['out'] = ns;
        }
        
        private function need_piece(remoteID:String, pieceID:int):void {
            trace("need piece, remoteID: " + remoteID + " pieceId: " + pieceID);
            peerlists_[remoteID]['private_publish'].send('need_piece', nc_.nearID, pieceID);
        }
        
        private function connect_to_Remote2(farID:String, playID:String):void {
            
            var ns:NetStream = new NetStream(nc_, farID);
            ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus2);
            var client:Object = new Object();
            client.has_piece = function(id:String):void {
                trace("has_piece callback");
            }
            client.who_has_piece = function(remoteID:String, pieceID:int):void {
                //trace("who has piece event");
                var who_has_piece_event:WhoHasPieceEvent = new WhoHasPieceEvent("WHO_HAS_PIECE");
                who_has_piece_event.remoteID = remoteID;
                who_has_piece_event.pieceID = pieceID;
                
                dispatchEvent(who_has_piece_event);
            }
            client.i_have_piece = function(remoteID:String, pieceID:int, have_piece:Boolean):void {
                trace('i have piece: remoteID: ' + remoteID + " pieceID: " + pieceID + " localId: " + nc_.nearID);
               
                var pieceIDstr:String = "" + pieceID;
                /*
                var attrs:String = "attrs: ";
               
                for (var v:* in piece_owners[pieceIDstr]) {
                    attrs = attrs + ", " + v;
                }
                trace(attrs);
                
                var ids:String = "ids: ";
                for (var x:* in piece_owners) {
                    ids = ids + ", " + x;
                }
                trace(ids);
                trace(piece_owners[pieceIDstr]["total_sent"]);
                */
                piece_owners[pieceIDstr]["total_sent"]--;
                
                if (!have_piece) {
                    piece_owners[pieceIDstr]["result"] = false;
                }
                
                if (piece_owners[pieceIDstr]["total_sent"] == 0) {
                    if(piece_owners[pieceIDstr]["result"]){
                        need_piece(remoteID, pieceID);
                    }
                    else {
                        var e:NoOneHasPieceEvent = new NoOneHasPieceEvent("NO_ONE_HAS_PIECE");
                        dispatchEvent(e);
                    }
                }
            }
            client.need_piece = function(remoteID:String, pieceID:int):void {
                var need_piece_event:NeedPieceEvent = new NeedPieceEvent("NEED_PIECE");
                need_piece_event.remoteID = remoteID;
                need_piece_event.pieceID = pieceID;
                
                dispatchEvent(need_piece_event);
            }
            client.piece_content = function(error:int, remoteID:String, id:int, content:ByteArray):void {
                var piece_content_event:PieceContentEvent = new PieceContentEvent("PIECE_CONTENT");
                piece_content_event.error = error;
                piece_content_event.remoteID = remoteID;
                piece_content_event.id = id;
                piece_content_event.content = content;
                
                dispatchEvent(piece_content_event);
            }
            ns.client = client;
            Logger.log("PLAY REMOTE farid: " + farID + " localID " + playID);
            ns.play(playID);
            
            if (!peerlists_.hasOwnProperty(farID)) {
                peerlists_[farID] = new Object();
            }
            
            peerlists_[farID]['out2'] = ns;
        }
        
        private function onNetStatusX(event:NetStatusEvent):void {
            trace("onNetStatusX, code: " + event.info.code);
        }
        
        private function onNetStatus2(event:NetStatusEvent):void {
            var desc:String = event.info.description;
            var farID:String = desc.split(' ')[2];
            
            if (isFarID_Connected(farID)) {
                //bc_.send("hello");
            }
            
            //if (event.info.code == "NetStream.Play.Start")
            //{
            //    peerlists_[farID]['private_publish_connected_to_remote'] = true;
            //}
            Logger.log("Broadcaster2: " + event.info.code + " farID: " + farID);
        }
        
        private function onNetStatus(event:NetStatusEvent):void {
            // NetStream.Play.Reset
            // NetStream.Play.Start
            Logger.log("Broadcaster: " + event.info.code);
        }
    }

}