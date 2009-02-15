package pl.maliboo.ftp.events
{
	import flash.events.Event;
	import flash.net.FileReference;
	
	import pl.maliboo.ftp.FTPFile;
	
	public class FTPTransferEvent extends Event
	{
		
		public static const TRANSFER_ERROR:String = 	"transferError";
		public static const TRANSFER_INIT:String = 		"transferInit";
		public static const TRANSFER_PROGRESS:String =	"transferProgress";
		public static const TRANSFER_COMPLETE:String = 	"transferComplete";
		
		private var _remoteFile:FTPFile;
		private var _bytesTotal:uint;
		private var _bytesTransferred:uint;
		
		
		public function FTPTransferEvent(type:String, 
			remoteFile:FTPFile=null,
			bytesTotal:uint=0, bytesTransferred:uint=0)
		{
			super(type);
			_remoteFile = remoteFile;
			_bytesTotal = bytesTotal;
			_bytesTransferred = bytesTransferred;
		}

		public function get bytesTransferred():uint
		{
			return _bytesTransferred;
		}

		public function get bytesTotal():uint
		{
			return _bytesTotal;
		}


		public function get remoteFile():FTPFile
		{
			return _remoteFile;
		}

		override public function clone():Event
		{
			return new FTPTransferEvent(type, remoteFile, bytesTotal, bytesTransferred);
		}
	}
}