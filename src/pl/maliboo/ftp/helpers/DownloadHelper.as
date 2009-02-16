package pl.maliboo.ftp.helpers
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataOutput;
	
	import pl.maliboo.ftp.FTPClient;
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.FTPFile;
	import pl.maliboo.ftp.PasvHelper;
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.events.FTPTransferEvent;
	import pl.maliboo.ftp.rfc959.Commands;
	import pl.maliboo.ftp.rfc959.ReplyCodes;

	public class DownloadHelper extends PasvHelper
	{
		private var file:FTPFile;
		private var stream:IDataOutput;
		private var progress:uint;
		private var bytesTotal:uint;
		
		public function DownloadHelper(ftp:FTPClient, file:FTPFile, stream:IDataOutput)
		{
			super(ftp);
			this.file = file;
			this.stream = stream;
		}
		
		override protected function restartSequence():void
		{
			progress = 0;
			bytesTotal = 0;
			super.restartSequence();
			prependCommand(new FTPCommand(Commands.SIZE, [file.nativePath]));
			appendCommand(new FTPCommand(Commands.RETR, [file.nativePath]));
			ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_INIT, file));
		}
		
		override protected function connectHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function closeHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
			progressHandler(null); //Check socket for bytes!
			ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_COMPLETE, file, bytesTotal, progress));
		}
		
		override protected function progressHandler(evt:ProgressEvent):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
			progress += socket.bytesAvailable;
			var buffer:ByteArray = new ByteArray();
			socket.readBytes(buffer);
			buffer.position = 0;
			stream.writeBytes(buffer);
			ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_PROGRESS, file, bytesTotal, progress));
		}
		
		private function handleReply(evt:FTPCommandEvent):void
		{
			switch (evt.reply.code)
			{
				case ReplyCodes.FILE_STATUS:
					var sizeMatch:Array = evt.reply.rawBody.match(/^\d{1,3}\s+(\d{1,})$/);
					bytesTotal = parseInt(sizeMatch[1]) as uint;
					break;
			}
		}
	}
}