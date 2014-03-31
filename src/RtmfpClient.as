package  
{
    import flash.events.Event;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLLoader;
    import flash.events.NetStatusEvent;
    import flash.events.EventDispatcher;
    import flash.net.Responder;
    import flash.utils.ByteArray;
    
	/**
     * ...
     * @author dista
     */
    public class RtmfpClient extends EventDispatcher
    {
        private var nc_:NetConnection;
        private var rtmfpUrl_:String;
        private var app_:String;
        private var track_:ITracker;
        private var track2_:ITracker;
        private var queryPeersRemoteCall:String = "getParticipants";
        private var bc_:Broadcaster;
        private var stream_:NetStream;
        private var nextP_:String = "h";
        private var sampleIndex_:int = -1;
        private var playlist_:Object;
        private var con_:NetConnection = new NetConnection();
        private var data_from_tracker_:Boolean;
        private var data_cache:Object = new Object();
        
        private var broadcaster_created:Boolean = false;
        
        public function RtmfpClient(url:String) 
        {
            rtmfpUrl_ = url;
            
            var pos:int = url.lastIndexOf("/");
            app_ = url.substr(pos + 1);
            
            data_cache["samples"] = new Array();
        }
        
        public function connect():void {
            nc_ = new NetConnection();
            nc_.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
            nc_.connect(rtmfpUrl_, app_);
        }
        
        private function getNextChunk():void {
            if (nextP_ != "samples")
            {
                track2_.getPiece("", playlist_[nextP_][0], playlist_[nextP_][1]);
                
                if (nextP_ == 'h') {
                    nextP_ = 'm';
                }
                else if (nextP_ == 'm') {
                    nextP_ = 'vs';
                }
                else if (nextP_ == 'vs') {
                    nextP_ = 'as';
                }
                else if (nextP_ == 'as') {
                    nextP_ = 'samples';
                }
            }
            else {
                sampleIndex_++;
                if (sampleIndex_ < playlist_["samples"].length) { 
                    data_from_tracker_ = true;
                    track2_.getPiece("", playlist_["samples"][sampleIndex_][0], playlist_["samples"][sampleIndex_][1]);
                    Logger.log("get piece from server: piece_id " + sampleIndex_);
                }
            }
            
        }
        
        private function setupData(data:ByteArray):void {
            if (nextP_ == 'm') {
                data_cache['h'] = data;
            }
            else if (nextP_ == 'vs') {
                data_cache['m'] = data;
            }
            else if (nextP_ == 'as') {
                data_cache['vs'] = data;
            }
            else if (nextP_ == 'samples' && sampleIndex_ == 0)
            {
                data_cache['as'] = data;
            }
            else {
                if (!data_cache.hasOwnProperty('samples')) {
                    data_cache['samples'] = new Array();
                }
                
                data_cache['samples'].push(data);
            }
        }
        
        private function onStatus(event:NetStatusEvent):void {
            if (event.info.code == "NetConnection.Connect.Success")
            {
                if (broadcaster_created) {
                    trace("WRONG PLACE")
                    return;
                }
                
                bc_ = new Broadcaster(nc_);
                bc_.addEventListener("WHO_HAS_PIECE", function(e:WhoHasPieceEvent):void {
                    if (data_cache['samples'].length > e.pieceID) {
                        bc_.i_have_piece(e.remoteID, e.pieceID, true);
                    }
                    else {
                        bc_.i_have_piece(e.remoteID, e.pieceID, false);
                    }
                } );
                
                bc_.addEventListener("NEED_PIECE", function(e:NeedPieceEvent):void {
                    bc_.piece_content(0, e.remoteID, e.pieceID, data_cache['samples'][e.pieceID]);
                } );
                
                bc_.addEventListener("NO_ONE_HAS_PIECE", function(e:NoOneHasPieceEvent):void {
                    sampleIndex_--;
                    getNextChunk();
                });
                
                bc_.addEventListener("PIECE_CONTENT", function(e:PieceContentEvent):void {
                    setupData(e.content);
                    stream_.appendBytes(e.content);
                    
                    Logger.log("get piece from peer: piece_id " + sampleIndex_ 
                        + " sample count: " + playlist_["samples"].length + " remoteID" + e.remoteID
                        + " id: " + e.id);
                    sampleIndex_++;
                    if (sampleIndex_ < playlist_["samples"].length) {
                        //Logger.log("who has piece");
                        bc_.who_has_piece(sampleIndex_);
                    }
                });
                
                track_ = new CumulusTracker(nc_);
                track2_ = new HttpTracker();
                track2_.addEventListener("ON_GET_PLAYLIST", function(e:PlayListEvent) {
                    playlist_ = e.playlist;
                    
                    con_.connect(null);
                    stream_ = new NetStream(con_);
                    stream_.client = new Object();
                    stream_.client["onMetaData"] = function(e:Object):void { 
                    };
                    
                    stream_.play(null);
                    
                    var newEvent:StreamCreatedEvent = new StreamCreatedEvent("STREAM_CREATED");
                    newEvent.stream = stream_;    
                    dispatchEvent(newEvent);
                    
                    track_.getPeers();
                    
                    getNextChunk();
                } );
                
                track2_.addEventListener("ON_GET_PIECE", function(e:PieceEvent):void { 
                    setupData(e.data);
                    
                    stream_.appendBytes(e.data);
                    //stream_.appendBytes(e.data);
                    if(nextP_ != "samples"){
                        getNextChunk();
                    }
                    else {
                        if (bc_.has_established_channel()) {
                            sampleIndex_++;
                            bc_.who_has_piece(sampleIndex_);
                            //sampleIndex_++;
                            //trace('who has piece');
                        }
                        else {
                            getNextChunk();
                        }
                    }
                    
                    } );
                    
                track_.addEventListener("ON_GET_PEERS", function(e:GetPeersEvent):void { 
                    
                    bc_.start(e.peers);
                } );
                
                trace("Connect Server Ok");
                //track_.getPeers();
                track2_.getPlaylist("xx");
                
                //nc_.removeEventListener(NetStatusEvent.NET_STATUS, onStatus);
                broadcaster_created = true;
            }
            else
            {
                Logger.log("RtmfpClient connect result: " + event.info.code);
                
                // P2P connections send messages to a NetConnection with a stream parameter
                // in the information object that indicates which NetStream the message pertains to.
                
                // if we close chrome tab, this event will trigger after 1 min. BAD...
                // if we close IE tab, this event will trigger immediatly.
                // Seems we have a bug here:
                // https://code.google.com/p/chromium/issues/detail?id=166304&q=rtmfp&colspec=ID%20Pri%20M%20Iteration%20ReleaseBlock%20Cr%20Status%20Owner%20Summary%20OS%20Modified
                if (event.info.hasOwnProperty("stream")) {
                    if (event.info.code == "NetStream.Connect.Closed") {
                        bc_.remotePeer(event.info.stream.farID);
                    }
                }
            }
        }
    }

}