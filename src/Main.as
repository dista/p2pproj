package 
{
	import flash.display.Sprite;
	import flash.events.Event;
    import flash.net.*;
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.utils.*;
    import flash.media.Video;
    import flash.media.Camera;
    
    // NOTO ALERT:::::::::: BE CAREFULL, YOU NEED TO ADD socket_policy_files
    // see https://gist.github.com/rbranson/810211
	
	/**
	 * ...
	 * @author dista
	 */
	public class Main extends Sprite 
	{
		private var con_:NetConnection;
        private var outStreams:Array;
        private var instreams:Array;
        private var rtmfpClient:RtmfpClient;
        private var broadcaster:Broadcaster;
        //private var ns:NetStream;
        
        private var video_:Video;
        
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
            
            outStreams = new Array();
            
            /*
            con_ = new NetConnection();
            con_.client = new Object();
            con_.client.participantChanged = onParticipantChanged;
            con_.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
            con_.connect("rtmfp://192.168.0.104:1935/app", "app");
            */
            
            /*
            var ncx:NetConnection = new NetConnection();
            ncx.connect(null);
            ns = new NetStream(ncx);
            
            ns.client = new Object();
            ns.client.onMetaData = function():void { trace("on metadata"); };
            ns.play(null);
            */
            
            rtmfpClient = new RtmfpClient("rtmfp://192.168.1.104:1935/app");
            //rtmfpClient.addEventListener(RtmfpClientConnectEvent.RTMFP_CLIENT_CONNECT_SUCCESS, onRtmfpClientConnectSuccess);
            rtmfpClient.connect();
            rtmfpClient.addEventListener("STREAM_CREATED", function(e:StreamCreatedEvent):void { 
                video_.attachNetStream(e.stream);
            } );
            
            video_ = new Video();
            //video_.width = 300;
            //video_.height = 200;
            addChild(video_);
            //video_.attachNetStream(ns);
            //video_.opaqueBackground = "#999";
            

            
            //video_.attachCamera(Camera.getCamera());
		}
        
        
        
        private function onParticipantChanged(farID:String):void
        {
            log("onParticipantChanged: " + farID);
            //p2pPublish(farID);
            
            /*
            for (var i:int; i < 10000; i++)
            {
                p2pPublish("xxx" + i);
            }
            */
        }
		
        private function onStatus(event:NetStatusEvent):void {
            if (event.info.code == "NetConnection.Connect.Success")
            {
                log(con_.nearID);
                p2pPublish(con_.nearID);
                con_.call("getParticipants", new Responder(onGetParticipantsResult), "app");
            }
            else
            {
                log("NetConnection, Status: " + event.info.code + "; farID: " + event.info.stream.farID);
            }
        }
        
        private function onOutStreamPeerConnected(caller:NetStream):Boolean
        {
            log("onpeer connected");
            log("farID" + caller.farID);
            p2pPublish(caller.farID);
            
            return true;
        }
        
        private function onOutStreamRequestChunk(segId:int, chunkId:int):void {
            log("onOutStreamRequestChunk: " + segId + ", " + chunkId);
            for (var i:int = 0; i < outStreams.length; i++)
            {
                outStreams[i].send("chunkMessage", "chunkMessage: " + segId + ", " + chunkId);
            }
        }
        
        private function onOutStreamNetStatus(event:NetStatusEvent):void {
            log("onOutStreamNetStatus: " + event.info.code);
            
            if ("NetStream.Play.Start" == event.info.code)
            {
                log("Send MSG");
                for (var i:int = 0; i < outStreams.length; i++)
                {
                    outStreams[i].send("chunkMessage", "outstream send chunkMessage", con_.nearID);
                }
            }
        }
        
        private function onGetParticipantsResult(obj:Object):void {
            instreams = new Array();
            for (var i:int = 0; i < obj.length; i++)
            {
                var peerFarId:String = obj[i].farID;
                
                var inStream_:NetStream = new NetStream(con_, peerFarId);
                instreams.push(inStream_);
                inStream_.client = new Object();
                inStream_.client.chunkMessage = onChunkMessage;
                inStream_.addEventListener(NetStatusEvent.NET_STATUS, onInStreamNetStatus);
                log("play: " + peerFarId);
                inStream_.play(peerFarId);
            }
        }
        
        private function p2pPublish(farID:String):void {
                var outStream_:NetStream = new NetStream(con_, NetStream.DIRECT_CONNECTIONS);
                outStream_.client = new Object();
                outStreams.push(outStream_);
                outStream_.client.onRequestChunk = onOutStreamRequestChunk;
                outStream_.client.onPeerConnect = onOutStreamPeerConnected;
                outStream_.addEventListener(NetStatusEvent.NET_STATUS, onOutStreamNetStatus);
                log("publish: " + farID);
                outStream_.publish(farID);
        }
        
        
        private function onInStreamNetStatus(event:NetStatusEvent):void {
            log("onInStreamNetStatus: " + event.info.code);
            
            if (event.info.code == "NetStream.Play.Start")
            {
                
            }
        }
        
        private function onChunkMessage(str:String, id:String):void {
            log(str + " id: " + id);
        }
        
        private function log(obj:Object):void {
            if (ExternalInterface.available)
            {
                ExternalInterface.call("log", obj.toString());
            }
            else {
                trace(obj);
            }
        }
	}
	
}