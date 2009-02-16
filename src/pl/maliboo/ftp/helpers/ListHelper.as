package pl.maliboo.ftp.helpers
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import pl.maliboo.ftp.FTPClient;
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.PasvHelper;
	import pl.maliboo.ftp.events.FTPTransferEvent;
	import pl.maliboo.ftp.rfc959.Commands;
	
	public class ListHelper extends PasvHelper
	{
		private var directory:String;
		
		public function ListHelper(ftp:FTPClient, directory:String)
		{
			super(ftp);
			this.directory = directory;
		}
		
		override protected function restartSequence():void
		{
			super.restartSequence();
			appendCommand(new FTPCommand(Commands.LIST, [directory]));
		}
		
		override protected function connectHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function closeHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
			progressHandler(null);
			trace("Kuniec!");
		}
		
		override protected function progressHandler(evt:ProgressEvent):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
			trace(socket.readUTFBytes(socket.bytesAvailable));
		}
	}
}