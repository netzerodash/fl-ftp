package pl.maliboo.ftp.helpers
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataOutput;
	
	import pl.maliboo.ftp.FTPClient;
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.FTPFile;
	import pl.maliboo.ftp.PasvHelper;
	import pl.maliboo.ftp.rfc959.Commands;

	public class DownloadHelper extends PasvHelper
	{
		private var file:FTPFile;
		private var stream:IDataOutput;
		
		public function DownloadHelper(ftp:FTPClient, file:FTPFile, stream:IDataOutput)
		{
			super(ftp);
			this.file = file;
			this.stream = stream;
			
		}
		
		protected function restartSequence():void
		{
			super.restartSequence();
			appendCommand(new FTPCommand(Commands.RETR, [file.nativePath]));
		}
		
		override protected function connectHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function closeHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function progressHandler(evt:ProgressEvent):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
			var buffer:ByteArray = new ByteArray();
			socket.readBytes(buffer);
			buffer.position = 0;
			stream.writeBytes(buffer);
		}
		
		override protected function ioErrorHandler(evt:IOErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function securityErrorHandler(evt:SecurityErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
	}
}