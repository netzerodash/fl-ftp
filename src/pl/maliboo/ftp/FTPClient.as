package pl.maliboo.ftp
{
	import flash.errors.IllegalOperationError;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import pl.maliboo.ftp.events.FTPTransferEvent;
	import pl.maliboo.ftp.helpers.DownloadHelper;
	import pl.maliboo.ftp.helpers.UploadHelper;
	
	[Event(name="transferInit",		type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferError",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferProgress",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferComplete",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	
	[Event(name="list",				type="pl.maliboo.ftp.events.FTPListEvent")]
	
	public class FTPClient extends FTPCore
	{
	
		private var transferHelper:PasvHelper;
		private var ftpFile:FTPFile;
		
		private var transferLock:Boolean;
		
		private var uploadHelper:UploadHelper;
		
		private var uploadSize:uint = 50000;
		
		public function FTPClient(host:String=null, port:int=0)
		{
			transferLock = false;
			//Remove locks after error and complete:
			addEventListener(FTPTransferEvent.TRANSFER_COMPLETE, handleComplete);
			addEventListener(FTPTransferEvent.TRANSFER_ERROR, handleComplete);
			super(host, port);
		}
		
		override public function get inTransaction():Boolean
		{
			return super.inTransaction || transferLock;
		}
		
		/**
		 * Downloads a file from server to stream (ByteArray, FileStream). Stream must be valid IDataOutput implementor.
		 * 
		 */
		//Maybe it should return Boolean, or IEventListener?
		//TODO: implement async streams?!
		//TODO: implement client lock on transfer
		//TODO: move to class (like upload)
		public function downloadFile(file:FTPFile, stream:IDataOutput):void
		{
			if (inTransaction) //Maybe dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			transferLock = true;
			transferHelper = new DownloadHelper(this, file, stream);
			transferHelper.start();
		}
		
		
		/**
		 * Uploads a stream (ByteArray, FileStream) to server. Stream must be valid IDataInput implementor.
		 * 
		 */ 
		/* 
		This is some kind of tricky&dirty hack. Due to Adobe ignorance we don't have
		ANY control over output progress, like in FileStream OutputProgress.OUTPUT_PROGRESS
		https://bugs.adobe.com/jira/browse/FP-6
		So we have to pretend that. Unfortunately server MUST support PASV and APPE commands.
		Nowadays I don't know any FTP server that don't support that:)
		Each "iteration" is bunch of:
		TYPE I
		SIZE [file]
		PASV
		APPE
		operations, so it takes some time to end this sequence. Uplod progress (Socket::flush)
		is "invisible" for API. Each chunk upload is discrete. More: see UploadHelper clas
		*/
		//TODO: implement client lock on transfer
		public function uploadFile(file:FTPFile, stream:IDataInput):void
		{
			if (inTransaction) //A moze dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			transferLock = true;
			transferHelper = new UploadHelper(this, file, stream, uploadSize);
			transferHelper.start();
		}
		
		public function cancelTransfer():void
		{
			transferHelper.abort();
			transferLock = false;
		}
		
		private function handleComplete(evt:FTPTransferEvent):void
		{
			//Locks are bad, maybe other idea?
			trace("Lock removed!");
			transferLock = false;
		}
	}
}	